# نموذج POCO F5 (marble) — Android/GKI 6.18

## الحالة

هذه الشجرة مبنية على Android Common Kernel فرع `android17-6.18-lts`، ويضيف فرع العمل `marble-gki-6.18-prototype` تهيئة أولية قابلة لإعادة البناء لنموذج POCO F5 / Redmi Note 12 Turbo (`marble`).

> **هذه ليست نواة قابلة للتفليش على POCO F5.** لا تحوّل المخرجات إلى `boot.img` أو `vendor_boot.img` ولا تفلّشها.

نجح التجميع الساكن لـ Linux 6.18.32 على arm64 باستخدام إعداد GKI العام وملف إعداد محافظ. الغرض من هذا النموذج هو تثبيت قاعدة ACK الحديثة، وتوفير نص بناء متكرر، وتوثيق فجوة النقل من مصدر Xiaomi 5.10.

| المجال | حالة النموذج |
|---|---|
| تجميع `Image` على arm64 | ناجح |
| وظائف Android العامة مثل Binder وUFS وGENI serial | ممكّنة من GKI |
| تعريف لوحة SM7475/marble | غير منقول |
| DTB/DTBO لـ marble | غير موجود |
| رسوميات KGSL/Adreno الخاصة | غير منقولة |
| CNSS/ICNSS وWi-Fi/BT الخاصة | غير منقولة |
| العرض واللمس والكاميرا والصوت والمودم | غير منقولة |
| توافق KMI النهائي | غير متحقق؛ BTF معطل مؤقتاً في بيئة النموذج |

## البناء

نفّذ من جذر الشجرة على مضيف Linux مزود بـ LLVM و`pahole` و`libdwarf` و`elfutils`:

```bash
./build_marble_gki_6_18_proto.sh
```

ينشئ النص مجلد مخرجات افتراضياً في:

```text
out/marble-gki-6.18-prototype/
```

ويضيف ملف الإعداد `arch/arm64/configs/marble_gki_6_18_proto.config` فوق `gki_defconfig`. هذا الملف **لا** يفعّل تعريفات Xiaomi 5.10 غير الموجودة في ACK 6.18 تلقائياً.

## ما يلزم قبل أول اختبار إقلاع

يلزم الحصول على مصدر Evolution X 17 المتزامن مع الإصدار المثبت، وملفات القسم المطابقة لنفس البناء: `boot.img` أو `init_boot.img` عند وجوده، و`vendor_boot.img`، و`dtbo.img`، و`vendor_dlkm.img`. بعد ذلك يجب نقل Device Tree وتعريفات منصة SM7475، وتكييف أو إعادة بناء وحدات vendor، واستعادة BTF باستخدام سلسلة أدوات Android المتوافقة، ثم إنشاء مسار استرداد مجرّب قبل أي تفليش.

## المراجع المصدرية

| المصدر | الغرض |
|---|---|
| https://android.googlesource.com/kernel/common | قاعدة Android Common Kernel `android17-6.18-lts`. |
| https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss | إعدادات ومصدر Xiaomi 5.10 المرجعي لـ marble. |
| https://github.com/Alaa91H/Kernel | مرجع GKI 5.10 السابق المستخدم للمقارنة فقط. |
