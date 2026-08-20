// SPDX-License-Identifier: GPL-2.0
/*
 * Qualcomm Secure Processor Subsystem (SPSS) remoteproc driver.
 *
 * The SPSS boot flow is distinct from the Q6 PAS flow: it uses SCSR status
 * bits for the two boot phases and a dedicated GLINK transport over SMEM.
 */

#include <linux/clk.h>
#include <linux/firmware.h>
#include <linux/firmware/qcom/qcom_scm.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/regulator/consumer.h>
#include <linux/remoteproc.h>
#include <linux/rpmsg/qcom_glink.h>
#include <linux/rpmsg/qcom_glink_spss.h>
#include <linux/soc/qcom/mdt_loader.h>

#include "qcom_common.h"
#include "remoteproc_internal.h"

#define SPSS_ERR_READY			0
#define SPSS_PBL_DONE			1
#define SPSS_WDOG_ERR			0x44554d50
#define SPSS_POLL_RETRIES		10
#define SPSS_POLL_TIMEOUT_MS		500
#define SPSS_WAIT_TIMEOUT_MS		(SPSS_POLL_RETRIES * SPSS_POLL_TIMEOUT_MS)
#define SPSS_PBL_LOG_VALUE		0xef000000
#define SPSS_PBL_LOG_MASK		0xff000000
#define SPSS_LOAD_FAILURE_MASK		BIT(0)

struct spss_regulator {
	struct regulator *reg;
	int uV;
	int uA;
};

struct spss_data {
	const char *firmware_name;
	int pas_id;
	const char *ssr_name;
	bool auto_boot;
};

struct spss_glink_subdev {
	struct rproc_subdev subdev;
	struct device *dev;
	struct device_node *node;
	const char *ssr_name;
	struct qcom_glink_spss *edge;
};

struct qcom_spss {
	struct device *dev;
	struct rproc *rproc;
	struct clk *xo;
	struct spss_regulator cx;
	int pas_id;
	struct completion start_done;
	phys_addr_t mem_phys;
	phys_addr_t mem_reloc;
	void *mem_region;
	size_t mem_size;
	int generic_irq;
	struct spss_glink_subdev glink_subdev;
	struct qcom_rproc_ssr ssr_subdev;
	struct qcom_sysmon *sysmon_subdev;
	void __iomem *irq_status;
	void __iomem *irq_clr;
	void __iomem *irq_mask;
	void __iomem *err_status;
	void __iomem *err_status_spare;
	void __iomem *rmb_gpm;
	u32 bits[2];
};

#define to_spss_glink_subdev(d) container_of(d, struct spss_glink_subdev, subdev)

static void spss_mask_irqs(struct qcom_spss *spss)
{
	writel(~0, spss->irq_mask);
}

static void spss_unmask_irqs(struct qcom_spss *spss)
{
	writel(~(BIT(spss->bits[SPSS_ERR_READY]) | BIT(spss->bits[SPSS_PBL_DONE])),
	       spss->irq_mask);
}

static void spss_clear_irq(struct qcom_spss *spss, unsigned int bit)
{
	writel(BIT(bit), spss->irq_clr);
}

static void spss_clear_pbl_done(struct qcom_spss *spss)
{
	u32 err = readl(spss->err_status);

	if (err)
		dev_err(spss->dev, "PBL error status: %#x\n", err);
	else
		dev_dbg(spss->dev, "SPSS PBL completed\n");

	spss_clear_irq(spss, spss->bits[SPSS_PBL_DONE]);
}

static void spss_clear_err_ready(struct qcom_spss *spss)
{
	spss_clear_irq(spss, spss->bits[SPSS_ERR_READY]);
	complete(&spss->start_done);
}

static bool spss_check_irq(struct qcom_spss *spss)
{
	u32 err = readl(spss->err_status_spare);
	u32 status = readl(spss->irq_status);

	if (status & BIT(spss->bits[SPSS_PBL_DONE]))
		spss_clear_pbl_done(spss);

	if (!(status & BIT(spss->bits[SPSS_ERR_READY])))
		return false;

	if (!err) {
		spss_clear_err_ready(spss);
		return true;
	}

	if (err == SPSS_WDOG_ERR)
		rproc_report_crash(spss->rproc, RPROC_WATCHDOG);
	else
		dev_err(spss->dev, "SPSS SW_INIT error: %#x\n", err);

	spss_clear_irq(spss, spss->bits[SPSS_ERR_READY]);
	return false;
}

static irqreturn_t spss_irq(int irq, void *data)
{
	struct qcom_spss *spss = data;

	spss_check_irq(spss);
	return IRQ_HANDLED;
}

static int spss_wait_for_start_done(struct qcom_spss *spss)
{
	unsigned long timeout;

	spss_unmask_irqs(spss);
	if (spss_check_irq(spss))
		return 0;

	timeout = wait_for_completion_timeout(&spss->start_done,
					     msecs_to_jiffies(SPSS_WAIT_TIMEOUT_MS));
	return timeout ? 0 : -ETIMEDOUT;
}

static int spss_glink_start(struct rproc_subdev *subdev)
{
	struct spss_glink_subdev *glink = to_spss_glink_subdev(subdev);

	glink->edge = qcom_glink_spss_register(glink->dev, glink->node);
	return PTR_ERR_OR_ZERO(glink->edge);
}

static void spss_glink_stop(struct rproc_subdev *subdev, bool crashed)
{
	struct spss_glink_subdev *glink = to_spss_glink_subdev(subdev);

	qcom_glink_spss_unregister(glink->edge);
	glink->edge = NULL;
}

static void spss_glink_unprepare(struct rproc_subdev *subdev)
{
	struct spss_glink_subdev *glink = to_spss_glink_subdev(subdev);

	qcom_glink_ssr_notify(glink->ssr_name);
}

static void spss_add_glink_subdev(struct rproc *rproc,
				  struct spss_glink_subdev *glink,
				  const char *ssr_name)
{
	struct device *dev = &rproc->dev;

	glink->node = of_get_child_by_name(dev->parent->of_node, "glink-edge");
	if (!glink->node)
		return;

	glink->ssr_name = kstrdup_const(ssr_name, GFP_KERNEL);
	if (!glink->ssr_name) {
		of_node_put(glink->node);
		glink->node = NULL;
		return;
	}

	glink->dev = dev;
	glink->subdev.start = spss_glink_start;
	glink->subdev.stop = spss_glink_stop;
	glink->subdev.unprepare = spss_glink_unprepare;
	rproc_add_subdev(rproc, &glink->subdev);
}

static void spss_remove_glink_subdev(struct rproc *rproc,
				     struct spss_glink_subdev *glink)
{
	if (!glink->node)
		return;

	rproc_remove_subdev(rproc, &glink->subdev);
	kfree_const(glink->ssr_name);
	of_node_put(glink->node);
	glink->node = NULL;
}

static int spss_load(struct rproc *rproc, const struct firmware *fw)
{
	struct qcom_spss *spss = rproc->priv;

	return qcom_mdt_load(spss->dev, fw, rproc->firmware, spss->pas_id,
			     spss->mem_region, spss->mem_phys, spss->mem_size,
			     &spss->mem_reloc);
}

static int spss_start(struct rproc *rproc)
{
	struct qcom_spss *spss = rproc->priv;
	int ret;

	ret = clk_prepare_enable(spss->xo);
	if (ret)
		return ret;

	ret = regulator_set_voltage(spss->cx.reg, spss->cx.uV, INT_MAX);
	if (ret)
		goto disable_xo;
	ret = regulator_set_load(spss->cx.reg, spss->cx.uA);
	if (ret)
		goto disable_xo;
	ret = regulator_enable(spss->cx.reg);
	if (ret)
		goto disable_xo;

	ret = qcom_scm_pas_auth_and_reset(spss->pas_id);
	if (ret) {
		dev_err(spss->dev, "failed to authenticate SPSS image: %d\n", ret);
		goto disable_cx;
	}

	ret = spss_wait_for_start_done(spss);
	if (ret)
		dev_err(spss->dev, "SPSS start timed out\n");

	disable_cx:
	regulator_disable(spss->cx.reg);
	regulator_set_load(spss->cx.reg, 0);
	regulator_set_voltage(spss->cx.reg, 0, INT_MAX);
	disable_xo:
	clk_disable_unprepare(spss->xo);
	return ret;
}

static int spss_stop(struct rproc *rproc)
{
	struct qcom_spss *spss = rproc->priv;
	int ret;

	ret = qcom_scm_pas_shutdown(spss->pas_id);
	if (ret)
		dev_err(spss->dev, "failed to stop SPSS: %d\n", ret);

	spss_mask_irqs(spss);
	reinit_completion(&spss->start_done);
	return ret;
}

static int spss_attach(struct rproc *rproc)
{
	struct qcom_spss *spss = rproc->priv;

	return spss_wait_for_start_done(spss);
}

static void *spss_da_to_va(struct rproc *rproc, u64 da, size_t len,
			   bool *is_iomem)
{
	struct qcom_spss *spss = rproc->priv;
	int offset = da - spss->mem_reloc;

	if (offset < 0 || offset + len > spss->mem_size)
		return NULL;

	if (is_iomem)
		*is_iomem = true;
	return spss->mem_region + offset;
}

static const struct rproc_ops spss_ops = {
	.start = spss_start,
	.stop = spss_stop,
	.attach = spss_attach,
	.load = spss_load,
	.da_to_va = spss_da_to_va,
	.parse_fw = qcom_register_dump_segments,
};

static int spss_init_regulator(struct qcom_spss *spss)
{
	struct device_node *np = spss->dev->of_node;
	u32 values[2];
	int ret;

	spss->cx.reg = devm_regulator_get(spss->dev, "cx");
	if (IS_ERR(spss->cx.reg))
		return PTR_ERR(spss->cx.reg);

	ret = of_property_read_u32_array(np, "cx-uV-uA", values,
					 ARRAY_SIZE(values));
	if (ret)
		return dev_err_probe(spss->dev, ret, "missing cx-uV-uA\n");

	spss->cx.uV = values[0];
	spss->cx.uA = values[1];
	return 0;
}

static int spss_alloc_memory_region(struct qcom_spss *spss)
{
	struct device_node *node;
	struct resource res;
	u32 extra_size = 0;
	int ret;

	node = of_parse_phandle(spss->dev->of_node, "memory-region", 0);
	if (!node)
		return dev_err_probe(spss->dev, -EINVAL, "missing memory-region\n");

	ret = of_address_to_resource(node, 0, &res);
	of_node_put(node);
	if (ret)
		return ret;

	of_property_read_u32(spss->dev->of_node, "qcom,extra-size", &extra_size);
	spss->mem_phys = spss->mem_reloc = res.start;
	spss->mem_size = resource_size(&res) + extra_size;
	spss->mem_region = devm_ioremap_wc(spss->dev, spss->mem_phys,
					   spss->mem_size);
	if (!spss->mem_region)
		return -EBUSY;

	return 0;
}

static int spss_init_mmio(struct platform_device *pdev, struct qcom_spss *spss)
{
	static const char * const names[] = {
		"rmb_general_purpose", "sp2soc_irq_status", "sp2soc_irq_clr",
		"sp2soc_irq_mask", "rmb_err", "rmb_err_spare2",
	};
	void __iomem **regs[] = {
		&spss->rmb_gpm, &spss->irq_status, &spss->irq_clr,
		&spss->irq_mask, &spss->err_status, &spss->err_status_spare,
	};
	struct resource *res;
	int ret;
	int i;

	for (i = 0; i < ARRAY_SIZE(names); i++) {
		res = platform_get_resource_byname(pdev, IORESOURCE_MEM, names[i]);
		*regs[i] = devm_ioremap_resource(&pdev->dev, res);
		if (IS_ERR(*regs[i]))
			return PTR_ERR(*regs[i]);
	}

	ret = of_property_read_u32_array(pdev->dev.of_node, "qcom,spss-scsr-bits",
					 spss->bits, ARRAY_SIZE(spss->bits));
	return ret;
}

static int qcom_spss_probe(struct platform_device *pdev)
{
	const struct spss_data *data;
	struct qcom_spss *spss;
	struct rproc *rproc;
	int ret;

	data = of_device_get_match_data(&pdev->dev);
	if (!data)
		return -EINVAL;
	if (!qcom_scm_is_available())
		return -EPROBE_DEFER;

	rproc = devm_rproc_alloc(&pdev->dev, dev_name(&pdev->dev), &spss_ops,
				 data->firmware_name, sizeof(*spss));
	if (!rproc)
		return -ENOMEM;

	rproc->auto_boot = data->auto_boot;
	rproc->recovery_disabled = true;
	rproc_coredump_set_elf_info(rproc, ELFCLASS32, EM_NONE);

	spss = rproc->priv;
	spss->dev = &pdev->dev;
	spss->rproc = rproc;
	spss->pas_id = data->pas_id;
	init_completion(&spss->start_done);
	platform_set_drvdata(pdev, spss);

	ret = device_init_wakeup(spss->dev, true);
	if (ret)
		return ret;
	ret = spss_init_mmio(pdev, spss);
	if (ret)
		goto disable_wakeup;
	ret = spss_alloc_memory_region(spss);
	if (ret)
		goto disable_wakeup;

	spss->xo = devm_clk_get(spss->dev, "xo");
	if (IS_ERR(spss->xo)) {
		ret = PTR_ERR(spss->xo);
		goto disable_wakeup;
	}
	ret = spss_init_regulator(spss);
	if (ret)
		goto disable_wakeup;

	if (!(readl(spss->rmb_gpm) & SPSS_LOAD_FAILURE_MASK) &&
	    !(readl(spss->err_status_spare - 4) & SPSS_LOAD_FAILURE_MASK))
		rproc->state = RPROC_DETACHED;

	spss_add_glink_subdev(rproc, &spss->glink_subdev, data->ssr_name);
	qcom_add_ssr_subdev(rproc, &spss->ssr_subdev, data->ssr_name);
	spss->sysmon_subdev = qcom_add_sysmon_subdev(rproc, data->ssr_name, -EINVAL);
	if (IS_ERR(spss->sysmon_subdev)) {
		ret = PTR_ERR(spss->sysmon_subdev);
		goto remove_subdevs;
	}

	spss_mask_irqs(spss);
	spss->generic_irq = platform_get_irq(pdev, 0);
	ret = devm_request_irq(spss->dev, spss->generic_irq, spss_irq,
			       IRQF_TRIGGER_RISING | IRQF_ONESHOT, "spss", spss);
	if (ret)
		goto remove_subdevs;

	ret = rproc_add(rproc);
	if (!ret)
		return 0;

remove_subdevs:
	qcom_remove_sysmon_subdev(spss->sysmon_subdev);
	qcom_remove_ssr_subdev(rproc, &spss->ssr_subdev);
	spss_remove_glink_subdev(rproc, &spss->glink_subdev);
disable_wakeup:
	device_init_wakeup(spss->dev, false);
	return ret;
}

static void qcom_spss_remove(struct platform_device *pdev)
{
	struct qcom_spss *spss = platform_get_drvdata(pdev);

	rproc_del(spss->rproc);
	qcom_remove_sysmon_subdev(spss->sysmon_subdev);
	qcom_remove_ssr_subdev(spss->rproc, &spss->ssr_subdev);
	spss_remove_glink_subdev(spss->rproc, &spss->glink_subdev);
	device_init_wakeup(spss->dev, false);
}

static const struct spss_data cape_spss = {
	.firmware_name = "spss.mdt",
	.pas_id = 14,
	.ssr_name = "spss",
	.auto_boot = false,
};

static const struct of_device_id qcom_spss_of_match[] = {
	{ .compatible = "qcom,cape-spss-pas", .data = &cape_spss },
	{ }
};
MODULE_DEVICE_TABLE(of, qcom_spss_of_match);

static struct platform_driver qcom_spss_driver = {
	.probe = qcom_spss_probe,
	.remove = qcom_spss_remove,
	.driver = {
		.name = "qcom-spss",
		.of_match_table = qcom_spss_of_match,
	},
};
module_platform_driver(qcom_spss_driver);

MODULE_DESCRIPTION("Qualcomm Secure Processor Subsystem remoteproc driver");
MODULE_LICENSE("GPL");
