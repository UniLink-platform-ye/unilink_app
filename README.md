# unilink_app — UniLink Academic Social Network

تطبيق Flutter للشبكة الاجتماعية الأكاديمية الموثوقة (UniLink Platform).

---

## Dynamic Branding (الهوية البصرية الديناميكية)

### كيف يستهلك التطبيق الـ Branding API

عند بدء تشغيل التطبيق يحدث التسلسل التالي:

```
main() → ThemeProvider.load()
              ↓
    BrandingService.fetchBranding()
              ↓
    GET /api/v1/branding.php
              ↓
    BrandingModel.fromJson(data)
              ↓
    ThemeProvider.buildTheme(brightness)
              ↓
    MaterialApp يستخدم الثيم الديناميكي
```

### الملفات الرئيسية

| الملف | الدور |
|-------|-------|
| `lib/models/branding_model.dart` | نموذج بيانات الهوية القادمة من API |
| `lib/services/branding_service.dart` | يجلب من الـ API ويُخزّن في SharedPreferences |
| `lib/providers/theme_provider.dart` | يبني ThemeData ديناميكياً من BrandingModel |
| `lib/config/api_config.dart` | يحتوي على `ApiConfig.branding` endpoint |

### الـ Cache

- عند أول تشغيل: يُجلب من الشبكة ويُخزَّن في `SharedPreferences`.
- عند التشغيل التالي: يُحمَّل من الـ Cache فوراً ثم يُحدَّث في الخلفية.
- عند فشل الشبكة: يُستخدم الـ Cache أو القيم الافتراضية (Deep Blue).

### القيم الافتراضية (Fallback)

```dart
BrandingModel.defaults = BrandingModel(
  platformName:    'UniLink',
  primaryColor:    Color(0xFF004D8C),  // أزرق ملكي
  secondaryColor:  Color(0xFF007786),
  accentColor:     Color(0xFF00B4D8),
  // ...
);
```

### استخدام الهوية في الشاشات

```dart
// داخل أي Widget
final branding = context.watch<ThemeProvider>().branding;

// الوصول للألوان
Color primary = branding.primaryColor;
String name   = branding.platformName;
String? logo  = branding.logoUrl;

// استخدام ألوان الثيم (من ThemeData)
final cs = Theme.of(context).colorScheme;
```

---

## Getting Started

```bash
flutter pub get
flutter run
```

### إعداد IP الخادم
عند التشغيل لأول مرة، اضغط أيقونة الإعدادات ⚙️ في شاشة تسجيل الدخول وأدخل IP خادم PHP.
