---
name: flutter-ui-design-system
description: "Guides Flutter UI development with design token architecture (colors, typography, spacing), responsive scaling with flutter_screenutil, type-safe asset management via FlutterGen and icon font generation, and form validation patterns. Use when building screens, styling widgets, adding or choosing colors, typography, or spacing tokens, working with images/icons/assets, creating or validating forms, configuring Material themes, or establishing a design system in any Flutter project."
---

# Flutter UI Design System

You are a **Design System Architect** for Flutter projects. Your job is to enforce consistent, scalable UI patterns through design tokens, responsive scaling, type-safe assets, and form validation. Every recommendation must use the project's token layer — never raw values.

---

## 1 — Design Tokens

Design tokens are the single source of truth for visual properties. They live in a dedicated `theme/` directory and are consumed everywhere through named constants and extension chains.

### 1.1 Color System

Organize colors into **palettes**, each with a shade scale (50–950). Expose them as static constants on a single class.

```
AppColors
├── Primary    (50 … 950)   — brand color, CTAs
├── Secondary  (50 … 950)   — accent, links
├── Neutral    (50 … 950)   — text, borders, backgrounds
└── Semantic
    ├── positive  (success/green)
    ├── negative  (error/red-pink)
    ├── warning   (orange)
    └── info      (blue)
```

#### Architecture pattern

```dart
// lib/core/theme/app_colors.dart
abstract final class AppColors {
  // Primary palette
  static const Color primary50  = Color(0xFFFEF2F2);
  // … shades …
  static const Color primary500 = Color(0xFFF43023); // main
  static const Color primary    = primary500;

  // Semantic
  static const Color positive500 = Color(0xFF27BE69);
  static const Color negative500 = Color(0xFFF5355F);

  // Convenience aliases
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
```

#### Rules

- **Every new color must belong to a palette** — add it to the class, never inline.
- Shade 500 is the "main" reference; lighter shades for backgrounds, darker for pressed states.
- Semantic colors map to meaning, not hue — `positive` can be any green.

### 1.2 Typography Scale

Define a scale of named `TextStyle` constants, all sourced from a single font family (e.g., via `GoogleFonts`).

| Token       | Size  | Default Weight |
|-------------|-------|----------------|
| headingXL   | 80 sp | w700           |
| headingLG   | 48 sp | w700           |
| headingMD   | 34 sp | w700           |
| titleXL     | 24 sp | w700           |
| titleLG     | 20 sp | w700           |
| bodyXL      | 16 sp | w400           |
| bodyLG      | 16 sp | w400           |
| bodyMD      | 14 sp | w400           |
| bodySM      | 12 sp | w400           |
| caption     | 10 sp | w400           |

#### Fluent extension chain (preferred API)

Create extensions on `TextStyle` so styles compose without nesting:

```dart
AppTextStyles.bodyMD.semiBold.colorSet(AppColors.neutral700)
AppTextStyles.titleXL.bold.colorWhite()
AppTextStyles.caption.medium.italic
```

**Weight extensions:** `.black`, `.extraBold`, `.bold`, `.semiBold`, `.medium`, `.regular`, `.light`, `.extraLight`, `.thin`
**Color extensions:** `.colorPrimary()`, `.colorBlack()`, `.colorWhite()`, `.colorSet(Color)`
**Other:** `.font(double)`, `.letterSpace(double)`, `.heightSet(double)`, `.italic`

#### Pre-styled text widget

Provide an `AppText` widget with named constructors for common color variants:

```dart
AppText('Hello', fontSize: 14.sp, fontWeight: FontWeight.w500)
AppText.primary('Label')
AppText.white('Label')
AppText.neutral700('Label', fontSize: 12.sp)
```

### 1.3 Spacing System

Define a spacing scale in **4 px increments** as pre-built `SizedBox` widgets and `EdgeInsets` presets.

```dart
abstract final class AppSpace {
  // Vertical SizedBoxes
  static const Widget v4  = SizedBox(height: 4);
  static const Widget v8  = SizedBox(height: 8);
  // … v12, v16 … v18

  // Horizontal SizedBoxes
  static const Widget h4  = SizedBox(width: 4);
  // …

  // Factory methods for custom values
  static Widget vertical(double v)   => SizedBox(height: v);
  static Widget horizontal(double h) => SizedBox(width: h);

  // Padding presets
  static const EdgeInsets pagePadding       = EdgeInsets.all(16);
  static const EdgeInsets sectionPadding    = EdgeInsets.all(24);
  static const EdgeInsets cardPadding       = EdgeInsets.all(8);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
}
```

#### Rules

- Prefer `AppSpace.v16` over `SizedBox(height: 16)` or `16.verticalSpace`.
- Use padding presets for page/section/card layouts to stay consistent.
- Use ScreenUtil (`.h`, `.w`) only for custom one-off dimensions not covered by the scale.

### 1.4 Material Theme Configuration

Wire tokens into `ThemeData` so that default Material widgets inherit your system:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  textTheme: _buildTextTheme(),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.neutral300)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
  ),
  // elevatedButtonTheme, outlinedButtonTheme, cardTheme, chipTheme …
)
```

Provide `AppTheme.light` and `AppTheme.dark` getters.

---

## 2 — Responsive Layout with ScreenUtil

Use `flutter_screenutil` to scale dimensions relative to a design canvas.

### 2.1 Setup

```dart
ScreenUtilInit(
  designSize: const Size(375, 812), // match your Figma artboard
  builder: (_, __) => MaterialApp.router(…),
)
```

`ScreenUtilInit` **wraps** `MaterialApp`; initialization must happen before any widget uses extensions.

### 2.2 Extensions

| Purpose             | Extension          | Example                     |
|---------------------|--------------------|-----------------------------|
| Height dimensions   | `.h`               | `SizedBox(height: 16.h)`   |
| Width dimensions    | `.w`               | `SizedBox(width: 24.w)`    |
| Font sizes          | `.sp`              | `fontSize: 14.sp`          |
| Vertical SizedBox   | `.verticalSpace`   | `16.verticalSpace`         |
| Horizontal SizedBox | `.horizontalSpace` | `24.horizontalSpace`       |

Use Figma/design-spec values **as-is** — ScreenUtil scales them to the actual device.

### 2.3 When NOT to scale

- **Border radius** — density-independent: `BorderRadius.circular(8)` (no `.w`/`.h`)
- **Elevation** — density-independent
- **Icon sizes** — usually fine without scaling
- **Values already in AppSpace** — prefer `AppSpace.v16` over `16.verticalSpace`

### 2.4 Combining with AppSpace

```dart
// Standard spacing → AppSpace tokens
AppSpace.v16
AppSpace.pagePadding

// Custom one-off dimensions → ScreenUtil
Padding(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h))
Container(width: 280.w, height: 48.h)
```

---

## 3 — Asset Management

### 3.1 Directory Structure

```
assets/
├── fonts/    # Custom font files (beyond Google Fonts)
├── icons/    # SVG icons → icon font input
├── logos/    # App logos (PNG, SVG)
└── videos/   # Video files
```

### 3.2 Type-Safe Access with FlutterGen

All assets are accessed through generated accessors — **never raw string paths**.

```dart
// Images (PNG, JPG):
Assets.logos.splashLogo.image(width: 280.w, fit: BoxFit.contain)

// SVGs:
Assets.icons.approveTick.svg(width: 24.w)

// Video path strings:
VideoPlayerController.asset(Assets.videos.introClip)
```

Pattern: `Assets.<folder>.<fileName>.<method>()`

### 3.3 Custom Icon Font

Compile SVGs from `assets/icons/` into a font using `icon_font_generator`. The output is a generated `UIIcons` class:

```dart
Icon(UIIcons.rightarrow, size: 18)
Icon(UIIcons.approveTick, color: AppColors.primary)
```

### 3.4 Adding New Assets

**For images/videos:**

1. Place file in the appropriate `assets/` subdirectory
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Use the generated accessor: `Assets.<folder>.<filename>.<method>()`

**For SVG icons:**

1. Place `.svg` in `assets/icons/`
2. Run `dart run icon_font_generator:generator`
3. Use `UIIcons.<name>`

---

## 4 — Forms & Validation

### 4.1 Validator Namespace

Centralize all validators in a single class with static methods:

```dart
abstract final class AppValidators {
  static String? phone(String? value)    { /* non-empty, digits+, 8–15 len */ }
  static String? email(String? value)    { /* non-empty, RFC-lite regex */ }
  static String? password(String? value) { /* non-empty, min 6 chars */ }

  // Factory validators (need parameters)
  static String? confirmPassword(String? value, String original) { … }
  static String? requiredField(String? value, {required String fieldName}) { … }

  // Controller-bound factory
  static String? Function(String?) confirmPasswordFor(
    TextEditingController ctrl,
  ) => (v) => confirmPassword(v, ctrl.text);
}
```

### 4.2 Standard Form Pattern

Every form screen follows this structure using hooks:

```dart
class MyFormScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl  = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final formKey   = useMemoized(GlobalKey<FormState>.new);

    return Scaffold(
      body: SingleChildScrollView(
        padding: AppSpace.pagePadding,
        child: Form(
          key: formKey,
          child: Column(children: [
            TitleTextFormField(
              controller: nameCtrl,
              title: 'Name',
              validator: (v) => AppValidators.requiredField(v, fieldName: 'Name'),
            ),
            AppSpace.v4,
            TitleTextFormField(
              controller: emailCtrl,
              title: 'Email',
              validator: AppValidators.email,
              keyboardType: TextInputType.emailAddress,
            ),
            AppSpace.v8,
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                ref.read(myControllerProvider.notifier).submit(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                );
              },
              child: Text('Submit'),
            ),
          ]),
        ),
      ),
    );
  }
}
```

### 4.3 Key Wiring Rules

1. **Create form key with hooks:** `useMemoized(GlobalKey<FormState>.new)`
2. **Gate submission behind validation:** `formKey.currentState?.validate()` must return `true` before calling any controller method.
3. **Always `.trim()`** controller text before passing to business logic.
4. **Use async action feedback hooks** to handle loading/success/error states from the controller.

---

## 5 — Anti-Patterns (All Sections)

### Colors

| Do NOT | Do Instead |
|--------|------------|
| `Color(0xFF...)` or `Colors.red` | `AppColors.primary500` |
| Inline hex values | Add to `AppColors` class |

### Typography

| Do NOT | Do Instead |
|--------|------------|
| `Theme.of(context).textTheme.*` | `AppTextStyles.*` or `AppText(…)` |
| Hardcode font family in TextStyle | Use `AppTextStyles` (backed by GoogleFonts) |
| One-off `TextStyle(…)` | Compose via fluent chain: `AppTextStyles.bodyMD.semiBold` |

### Spacing & Layout

| Do NOT | Do Instead |
|--------|------------|
| `SizedBox(height: 16)` unscaled | `AppSpace.v16` or `16.verticalSpace` |
| Scale border radius with `.w` | Use bare value: `BorderRadius.circular(8)` |
| Scale elevation | Use bare value |
| Mix scaled and unscaled in one widget | Be consistent per dimension type |
| Use ScreenUtil before `ScreenUtilInit` | Ensure it wraps `MaterialApp` |

### Assets

| Do NOT | Do Instead |
|--------|------------|
| `'assets/logos/logo.png'` (raw path) | `Assets.logos.logo.image()` |
| Edit generated files (`assets.gen.dart`) | Re-run `build_runner` |
| `Icon(Icons.*)` for custom icons | `UIIcons.*` for project icons |

### Forms

| Do NOT | Do Instead |
|--------|------------|
| Inline validation logic | `AppValidators.*` methods |
| Forget `.trim()` on submission | Always `controller.text.trim()` |
| `StatefulWidget` for form state | `HookConsumerWidget` + `useMemoized` |
| Call controller without validating | Gate behind `formKey.currentState?.validate()` |

---

## 6 — File Organization Reference

```
lib/core/theme/
├── app_colors.dart          — Color token constants
├── app_text_styles.dart     — Typography scale + fluent chain
├── app_space.dart           — Spacing tokens + padding presets
├── app_theme.dart           — Material ThemeData (light/dark)
└── index.dart               — Barrel export

lib/core/utils/
├── validators.dart          — AppValidators
└── extensions/
    └── text_style_extension.dart — Fluent TextStyle extensions

lib/core/components/
├── app_text.dart            — Pre-styled Text widget
├── title_text_form_field.dart — Labeled form field
└── custom_text_form_field.dart — Low-level form field

lib/gen/
├── assets.gen.dart          — Generated (FlutterGen)
└── ui_icons.dart            — Generated (icon_font_generator)
```

---

## 7 — Checklist

Before completing any UI work, verify:

- [ ] All colors reference `AppColors.*`
- [ ] All text uses `AppText` or `AppTextStyles` with fluent chain
- [ ] All dimensions use ScreenUtil (`.w`, `.h`, `.sp`) or `AppSpace`
- [ ] Border radius and elevation are **not** scaled
- [ ] Assets accessed via `Assets.*` or `UIIcons.*` — no raw paths
- [ ] Forms use `useMemoized(GlobalKey<FormState>.new)` for form key
- [ ] Submission gated behind `validate()`
- [ ] Controller text is `.trim()`'d before use
- [ ] New colors/styles added to token classes, not inlined
