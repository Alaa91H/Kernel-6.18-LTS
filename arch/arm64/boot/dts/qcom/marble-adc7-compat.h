/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * PM8350/PM8350B ADC7 channel IDs used by the Xiaomi marble Device Tree.
 * These legacy numeric channel IDs are absent from the ACK 6.18 headers.
 */
#ifndef __DTS_QCOM_MARBLE_ADC7_COMPAT_H__
#define __DTS_QCOM_MARBLE_ADC7_COMPAT_H__

#include <dt-bindings/iio/qcom,spmi-adc7-pm8350.h>
#include <dt-bindings/iio/qcom,spmi-adc7-pm8350b.h>

#ifndef PM8350_SID
#define PM8350_SID				0
#endif

/* ACK defines these as function-like macros; marble uses fixed PM8350 SID. */
#ifdef PM8350_ADC7_REF_GND
#undef PM8350_ADC7_REF_GND
#endif
#define PM8350_ADC7_REF_GND			(PM8350_SID << 8 | 0x00)
#ifdef PM8350_ADC7_1P25VREF
#undef PM8350_ADC7_1P25VREF
#endif
#define PM8350_ADC7_1P25VREF			(PM8350_SID << 8 | 0x01)
#ifdef PM8350_ADC7_DIE_TEMP
#undef PM8350_ADC7_DIE_TEMP
#endif
#define PM8350_ADC7_DIE_TEMP			(PM8350_SID << 8 | 0x03)
#ifdef PM8350_ADC7_AMUX_THM1_100K_PU
#undef PM8350_ADC7_AMUX_THM1_100K_PU
#endif
#define PM8350_ADC7_AMUX_THM1_100K_PU		(PM8350_SID << 8 | 0x44)
#ifdef PM8350_ADC7_AMUX_THM2_100K_PU
#undef PM8350_ADC7_AMUX_THM2_100K_PU
#endif
#define PM8350_ADC7_AMUX_THM2_100K_PU		(PM8350_SID << 8 | 0x45)
#ifdef PM8350_ADC7_AMUX_THM3_100K_PU
#undef PM8350_ADC7_AMUX_THM3_100K_PU
#endif
#define PM8350_ADC7_AMUX_THM3_100K_PU		(PM8350_SID << 8 | 0x46)
#ifdef PM8350_ADC7_VPH_PWR
#undef PM8350_ADC7_VPH_PWR
#endif
#define PM8350_ADC7_VPH_PWR			(PM8350_SID << 8 | 0x8e)
#ifdef PM8350B_ADC7_ICHG_FB
#undef PM8350B_ADC7_ICHG_FB
#endif
#define PM8350B_ADC7_ICHG_FB			(PM8350B_SID << 8 | 0xa1)

#endif /* __DTS_QCOM_MARBLE_ADC7_COMPAT_H__ */
