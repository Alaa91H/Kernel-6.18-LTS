/* SPDX-License-Identifier: GPL-2.0 */
#ifndef __QCOM_GLINK_SPSS_H__
#define __QCOM_GLINK_SPSS_H__

#include <linux/err.h>

struct device;
struct device_node;
struct qcom_glink_spss;

#if IS_ENABLED(CONFIG_RPMSG_QCOM_GLINK_SPSS)
struct qcom_glink_spss *qcom_glink_spss_register(struct device *parent,
						  struct device_node *node);
void qcom_glink_spss_unregister(struct qcom_glink_spss *spss);
#else
static inline struct qcom_glink_spss *
qcom_glink_spss_register(struct device *parent, struct device_node *node)
{
	return ERR_PTR(-ENODEV);
}

static inline void qcom_glink_spss_unregister(struct qcom_glink_spss *spss)
{
}
#endif

#endif /* __QCOM_GLINK_SPSS_H__ */
