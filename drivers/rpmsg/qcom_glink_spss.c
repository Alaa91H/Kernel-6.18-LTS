// SPDX-License-Identifier: GPL-2.0
/*
 * Qualcomm GLINK transport for the Secure Processor Subsystem (SPSS).
 *
 * The SPSS endpoint uses a small shared-memory FIFO descriptor advertised
 * through the registers described by the glink-edge Device Tree child.
 */

#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/mailbox_client.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/sizes.h>
#include <linux/soc/qcom/smem.h>

#include "qcom_glink_native.h"

#define FIFO_FULL_RESERVE		8
#define TX_BLOCKED_CMD_RESERVE		8
#define SMEM_GLINK_NATIVE_XPRT_DESCRIPTOR	478
#define SPSS_TX_FIFO_SIZE		SZ_2K
#define SPSS_RX_FIFO_SIZE		SZ_2K

struct glink_spss_cfg {
	__le32 tx_tail;
	__le32 tx_head;
	__le32 tx_fifo_size;
	__le32 rx_tail;
	__le32 rx_head;
	__le32 rx_fifo_size;
};

struct glink_spss_pipe {
	struct qcom_glink_pipe native;
	__le32 *tail;
	__le32 *head;
	void *fifo;
};

struct qcom_glink_spss;

struct qcom_glink_spss *qcom_glink_spss_register(struct device *parent,
						  struct device_node *node);
void qcom_glink_spss_unregister(struct qcom_glink_spss *spss);

struct qcom_glink_spss {
	struct device *dev;
	struct qcom_glink *glink;
	struct mbox_client mbox_client;
	struct mbox_chan *mbox_chan;
	int irq;
	struct glink_spss_pipe rx_pipe;
	struct glink_spss_pipe tx_pipe;
};

#define to_spss_pipe(p) container_of(p, struct glink_spss_pipe, native)

static size_t glink_spss_rx_avail(struct qcom_glink_pipe *glink_pipe)
{
	struct glink_spss_pipe *pipe = to_spss_pipe(glink_pipe);
	u32 head = le32_to_cpu(READ_ONCE(*pipe->head));
	u32 tail = le32_to_cpu(READ_ONCE(*pipe->tail));

	if (head < tail)
		return pipe->native.length - tail + head;

	return head - tail;
}

static void glink_spss_rx_peek(struct qcom_glink_pipe *glink_pipe, void *data,
				unsigned int offset, size_t count)
{
	struct glink_spss_pipe *pipe = to_spss_pipe(glink_pipe);
	size_t len;
	u32 tail = le32_to_cpu(READ_ONCE(*pipe->tail));

	tail += offset;
	if (tail >= pipe->native.length)
		tail -= pipe->native.length;

	len = min_t(size_t, count, pipe->native.length - tail);
	memcpy(data, pipe->fifo + tail, len);
	if (len != count)
		memcpy(data + len, pipe->fifo, count - len);
}

static void glink_spss_rx_advance(struct qcom_glink_pipe *glink_pipe,
				  size_t count)
{
	struct glink_spss_pipe *pipe = to_spss_pipe(glink_pipe);
	u32 tail = le32_to_cpu(READ_ONCE(*pipe->tail));

	tail += count;
	if (tail >= pipe->native.length)
		tail -= pipe->native.length;

	WRITE_ONCE(*pipe->tail, cpu_to_le32(tail));
}

static size_t glink_spss_tx_avail(struct qcom_glink_pipe *glink_pipe)
{
	struct glink_spss_pipe *pipe = to_spss_pipe(glink_pipe);
	u32 head = le32_to_cpu(READ_ONCE(*pipe->head));
	u32 tail = le32_to_cpu(READ_ONCE(*pipe->tail));
	u32 avail;

	if (tail <= head)
		avail = pipe->native.length - head + tail;
	else
		avail = tail - head;

	if (avail < FIFO_FULL_RESERVE + TX_BLOCKED_CMD_RESERVE)
		return 0;

	return avail - FIFO_FULL_RESERVE - TX_BLOCKED_CMD_RESERVE;
}

static unsigned int glink_spss_tx_write_one(struct glink_spss_pipe *pipe,
					    unsigned int head,
					    const void *data, size_t count)
{
	size_t len = min_t(size_t, count, pipe->native.length - head);

	memcpy(pipe->fifo + head, data, len);
	if (len != count)
		memcpy(pipe->fifo, data + len, count - len);

	head += count;
	if (head >= pipe->native.length)
		head -= pipe->native.length;

	return head;
}

static void glink_spss_tx_write(struct qcom_glink_pipe *glink_pipe,
				 const void *hdr, size_t hlen,
				 const void *data, size_t dlen)
{
	struct glink_spss_pipe *pipe = to_spss_pipe(glink_pipe);
	unsigned int head = le32_to_cpu(READ_ONCE(*pipe->head));

	head = glink_spss_tx_write_one(pipe, head, hdr, hlen);
	head = glink_spss_tx_write_one(pipe, head, data, dlen);
	head = ALIGN(head, 8);
	if (head >= pipe->native.length)
		head -= pipe->native.length;

	/* Publish FIFO contents before publishing the new producer index. */
	wmb();
	WRITE_ONCE(*pipe->head, cpu_to_le32(head));
}

static void glink_spss_tx_kick(struct qcom_glink_pipe *glink_pipe)
{
	struct glink_spss_pipe *pipe = to_spss_pipe(glink_pipe);
	struct qcom_glink_spss *spss =
		container_of(pipe, struct qcom_glink_spss, tx_pipe);

	mbox_send_message(spss->mbox_chan, NULL);
	mbox_client_txdone(spss->mbox_chan, 0);
}

static irqreturn_t glink_spss_irq(int irq, void *data)
{
	struct qcom_glink_spss *spss = data;

	qcom_glink_native_rx(spss->glink);
	return IRQ_HANDLED;
}

static void glink_spss_device_release(struct device *dev)
{
	of_node_put(dev->of_node);
	kfree(dev);
}

static int glink_spss_advertise_cfg(struct device *dev, u32 size,
				    phys_addr_t addr)
{
	struct resource addr_r;
	struct resource size_r;
	__le64 __iomem *spss_addr;
	__le32 __iomem *spss_size;
	int addr_idx;
	int size_idx;

	addr_idx = of_property_match_string(dev->of_node, "reg-names",
					    "qcom,spss-addr");
	size_idx = of_property_match_string(dev->of_node, "reg-names",
					    "qcom,spss-size");
	if (addr_idx < 0 || size_idx < 0)
		return dev_err_probe(dev, -EINVAL, "missing SPSS descriptor registers\n");

	if (of_address_to_resource(dev->of_node, addr_idx, &addr_r) ||
	    of_address_to_resource(dev->of_node, size_idx, &size_r))
		return dev_err_probe(dev, -EINVAL, "invalid SPSS descriptor registers\n");

	spss_addr = devm_ioremap(dev, addr_r.start, resource_size(&addr_r));
	spss_size = devm_ioremap(dev, size_r.start, resource_size(&size_r));
	if (!spss_addr || !spss_size)
		return -ENOMEM;

	writeq_relaxed(addr, spss_addr);
	writel_relaxed(size, spss_size);
	return 0;
}

struct qcom_glink_spss *qcom_glink_spss_register(struct device *parent,
						  struct device_node *node)
{
	struct glink_spss_cfg *cfg;
	struct qcom_glink_spss *spss;
	struct device *dev;
	u32 remote_pid;
	size_t tx_size = SPSS_TX_FIFO_SIZE;
	size_t rx_size = SPSS_RX_FIFO_SIZE;
	size_t size = tx_size + rx_size + sizeof(*cfg);
	int ret;

	dev = kzalloc(sizeof(*dev), GFP_KERNEL);
	if (!dev)
		return ERR_PTR(-ENOMEM);

	dev->parent = parent;
	dev->of_node = of_node_get(node);
	dev->release = glink_spss_device_release;
	dev_set_name(dev, "%s:%s", node->parent->name, node->name);
	ret = device_register(dev);
	if (ret) {
		put_device(dev);
		return ERR_PTR(ret);
	}

	spss = devm_kzalloc(dev, sizeof(*spss), GFP_KERNEL);
	if (!spss) {
		ret = -ENOMEM;
		goto err_unregister_device;
	}
	spss->dev = dev;

	ret = of_property_read_u32(node, "qcom,remote-pid", &remote_pid);
	if (ret)
		goto err_unregister_device;

	ret = qcom_smem_alloc(remote_pid, SMEM_GLINK_NATIVE_XPRT_DESCRIPTOR, size);
	if (ret && ret != -EEXIST)
		goto err_unregister_device;

	cfg = qcom_smem_get(remote_pid, SMEM_GLINK_NATIVE_XPRT_DESCRIPTOR, &size);
	if (IS_ERR(cfg)) {
		ret = PTR_ERR(cfg);
		goto err_unregister_device;
	}
	if (size != tx_size + rx_size + sizeof(*cfg)) {
		ret = -EINVAL;
		goto err_unregister_device;
	}

	cfg->tx_fifo_size = cpu_to_le32(tx_size);
	cfg->rx_fifo_size = cpu_to_le32(rx_size);
	spss->tx_pipe.tail = &cfg->tx_tail;
	spss->tx_pipe.head = &cfg->tx_head;
	spss->tx_pipe.fifo = (u8 *)cfg + sizeof(*cfg);
	spss->tx_pipe.native.length = tx_size;
	spss->rx_pipe.tail = &cfg->rx_tail;
	spss->rx_pipe.head = &cfg->rx_head;
	spss->rx_pipe.fifo = (u8 *)cfg + sizeof(*cfg) + tx_size;
	spss->rx_pipe.native.length = rx_size;

	spss->rx_pipe.native.avail = glink_spss_rx_avail;
	spss->rx_pipe.native.peek = glink_spss_rx_peek;
	spss->rx_pipe.native.advance = glink_spss_rx_advance;
	spss->tx_pipe.native.avail = glink_spss_tx_avail;
	spss->tx_pipe.native.write = glink_spss_tx_write;
	spss->tx_pipe.native.kick = glink_spss_tx_kick;

	WRITE_ONCE(*spss->rx_pipe.tail, 0);
	WRITE_ONCE(*spss->tx_pipe.head, 0);

	ret = glink_spss_advertise_cfg(dev, size, qcom_smem_virt_to_phys(cfg));
	if (ret)
		goto err_unregister_device;

	spss->mbox_client.dev = dev;
	spss->mbox_client.knows_txdone = true;
	spss->mbox_chan = mbox_request_channel(&spss->mbox_client, 0);
	if (IS_ERR(spss->mbox_chan)) {
		ret = PTR_ERR(spss->mbox_chan);
		goto err_unregister_device;
	}

	spss->glink = qcom_glink_native_probe(dev, GLINK_FEATURE_INTENT_REUSE,
					     &spss->rx_pipe.native,
					     &spss->tx_pipe.native, false);
	if (IS_ERR(spss->glink)) {
		ret = PTR_ERR(spss->glink);
		goto err_free_mbox;
	}

	spss->irq = of_irq_get(node, 0);
	if (spss->irq < 0) {
		ret = spss->irq;
		goto err_remove_glink;
	}

	ret = devm_request_irq(dev, spss->irq, glink_spss_irq, IRQF_NO_SUSPEND,
				       "glink-spss", spss);
	if (ret)
		goto err_remove_glink;

	return spss;

err_remove_glink:
	qcom_glink_native_remove(spss->glink);
err_free_mbox:
	mbox_free_channel(spss->mbox_chan);
err_unregister_device:
	device_unregister(dev);
	return ERR_PTR(ret);
}
EXPORT_SYMBOL_GPL(qcom_glink_spss_register);

void qcom_glink_spss_unregister(struct qcom_glink_spss *spss)
{
	if (!spss)
		return;

	qcom_glink_native_remove(spss->glink);
	mbox_free_channel(spss->mbox_chan);
	device_unregister(spss->dev);
}
EXPORT_SYMBOL_GPL(qcom_glink_spss_unregister);

MODULE_DESCRIPTION("Qualcomm GLINK transport for SPSS");
MODULE_LICENSE("GPL");
