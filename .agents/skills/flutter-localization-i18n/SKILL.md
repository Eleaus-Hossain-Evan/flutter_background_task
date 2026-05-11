---
name: flutter-localization-i18n
description: "Comprehensive AppLocalizations and i18n workflow for Flutter apps using ARB files, gen-l10n, Riverpod locale persistence, and context.local accessors. Use when adding or updating localized keys, implementing English/Bengali translations, wiring locale switching, or configuring MaterialApp localization delegates."
argument-hint: "Describe your localization task (new keys, placeholders/plurals, locale switcher, or setup fixes)"
---

# Flutter AppLocalizations and I18n Guide

Use this skill when working on localization in this repository. It documents the end-to-end workflow for ARB authoring, generation, runtime locale selection, and persistence.

## What This Skill Produces

- A consistent localization implementation using `AppLocalizations` and ARB files.
- Reliable English (`en`) and Bengali (`bn`) translations with generated Dart APIs.
- Locale switching through Riverpod with persisted user preference.
- Clean and convenient string access via `context.local`.

## Repository Baseline (Current Implementation)

- ARB sources: `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb`
- L10n config: `l10n.yaml`
- Generated APIs: `lib/l10n/app_localizations*.dart` (read-only)
- Context extension: `lib/core/utils/extensions/context_extensions.dart`
- Locale provider: `lib/core/providers/app_locale_provider.dart`
- SharedPreferences provider: `lib/core/providers/shared_preferences_provider.dart`
- SharedPreferences bootstrap override: `lib/main.dart`
- MaterialApp localization wiring: `lib/app.dart`

## Workflow

### 1. Confirm Localization Configuration

1. Verify `l10n.yaml` points to `lib/l10n` and outputs `AppLocalizations`.
2. Verify `pubspec.yaml` has:
   - `flutter_localizations` under `dependencies`
   - `flutter.generate: true`
3. Verify `MaterialApp.router` in `lib/app.dart` includes:
   - `locale: ref.watch(appLocaleProvider)`
   - `localizationsDelegates: AppLocalizations.localizationsDelegates`
   - `supportedLocales: AppLocalizations.supportedLocales`

### 2. Add or Update ARB Keys

Always treat `app_en.arb` as the source-of-truth template and keep `app_bn.arb` in sync.

1. Add the key in `lib/l10n/app_en.arb` with metadata:

```json
{
  "emergencyHelp": "Emergency help",
  "@emergencyHelp": {
    "description": "CTA label for opening emergency assistance"
  }
}
```

2. Add the same key in `lib/l10n/app_bn.arb`:

```json
{
  "emergencyHelp": "জরুরি সহায়তা"
}
```

3. Keep key names stable and descriptive (`camelCase`).

### 3. Handle Dynamic Strings Correctly

Use placeholders, plurals, and select statements in ARB rather than manual string interpolation in widgets.

#### 3.1 Parameterized String Example

`lib/l10n/app_en.arb`:

```json
{
  "welcomeUser": "Welcome, {name}",
  "@welcomeUser": {
    "description": "Greets the signed-in user by name",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "Evan"
      }
    }
  }
}
```

`lib/l10n/app_bn.arb`:

```json
{
  "welcomeUser": "স্বাগতম, {name}"
}
```

Usage:

```dart
Text(context.local.welcomeUser(userName))
```

#### 3.2 Pluralization Example

`lib/l10n/app_en.arb`:

```json
{
  "activeAlerts": "{count, plural, =0{No active alerts} =1{1 active alert} other{{count} active alerts}}",
  "@activeAlerts": {
    "description": "Shows the number of currently active alerts",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

`lib/l10n/app_bn.arb`:

```json
{
  "activeAlerts": "{count, plural, =0{কোনো সক্রিয় সতর্কতা নেই} =1{১টি সক্রিয় সতর্কতা} other{{count}টি সক্রিয় সতর্কতা}}"
}
```

Usage:

```dart
Text(context.local.activeAlerts(alertCount))
```

### 4. Generate Localization Dart Files

After ARB updates:

```bash
flutter gen-l10n
```

If provider annotations were changed in the same task, also run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not edit `lib/l10n/app_localizations*.dart` manually.

### 5. Use Context Extension for Access

The repository standard is `context.local` from `lib/core/utils/extensions/context_extensions.dart`:

```dart
extension BuildContextExtensions on BuildContext {
  AppLocalizations get local {
    final localizations = AppLocalizations.of(this);
    return localizations;
  }
}
```

Preferred UI usage:

```dart
Text(context.local.commonRetry)
```

Avoid direct `AppLocalizations.of(context)` in widgets unless required for low-level APIs.

### 6. Manage Locale with Riverpod

Use `AppLocale` notifier in `lib/core/providers/app_locale_provider.dart`.

Key behavior:

- Reads persisted language code from SharedPreferences key: `app_locale_language_code`
- Defaults to English (`en`) when absent
- Persists changes via `setLanguageCode` / `setLocale`

Example UI action:

```dart
await ref.read(appLocaleProvider.notifier).setLanguageCode('bn');
```

Example toggle:

```dart
final locale = ref.watch(appLocaleProvider);
final isBengali = locale.languageCode == 'bn';

await ref
    .read(appLocaleProvider.notifier)
    .setLanguageCode(isBengali ? 'en' : 'bn');
```

### 7. Persist Locale via SharedPreferences Bootstrap

Keep locale persistence wired through the provider override in `lib/main.dart`:

```dart
final sharedPreferences = await SharedPreferences.getInstance();

runApp(
  ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) => sharedPreferences),
    ],
    child: const App(),
  ),
);
```

Never call `SharedPreferences.getInstance()` directly from screens/providers outside bootstrap.

### 8. Configure MaterialApp Localization Properly

`lib/app.dart` should remain aligned with generated localizations:

```dart
final locale = ref.watch(appLocaleProvider);

MaterialApp.router(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

### 9. Add Locale Switching UI (Pattern)

Use a `HookConsumerWidget` or `ConsumerWidget` and write through the notifier:

```dart
DropdownButton<String>(
  value: ref.watch(appLocaleProvider).languageCode,
  items: const [
    DropdownMenuItem(value: 'en', child: Text('English')),
    DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
  ],
  onChanged: (code) {
    if (code == null) return;
    ref.read(appLocaleProvider.notifier).setLanguageCode(code);
  },
)
```

## Decision Branches

### Branch A: Static Text vs Dynamic Text

- Static text: add a plain key/value to both ARBs.
- Dynamic text with variables: add `placeholders` metadata.
- Quantities/counts: use ICU plural syntax.

### Branch B: Existing Key vs New Key

- Existing key but changed wording: update all locale ARBs for that key.
- New key: add metadata in `app_en.arb` and translation in `app_bn.arb`.

### Branch C: Locale Data Source

- Persisted locale exists: provider loads that locale.
- No persisted locale: provider defaults to `'en'`.

### Branch D: File Types Changed

- ARB-only change: run `flutter gen-l10n`.
- Riverpod provider annotation changed: run `build_runner` too.

## Quality Criteria (Completion Checks)

1. Every newly added key exists in both `app_en.arb` and `app_bn.arb`.
2. New English keys include `@description` metadata.
3. Generated localizations compile (`flutter gen-l10n` succeeds).
4. UI uses `context.local.<key>` instead of hardcoded text.
5. Locale switches immediately when `appLocaleProvider` updates.
6. Selected locale persists across app restart via SharedPreferences.
7. `MaterialApp.router` delegates/locales remain wired to `AppLocalizations`.
8. No manual edits to generated localization files.

## Common Pitfalls

- Adding a key only to English ARB and forgetting Bengali.
- Missing placeholder metadata for parameterized messages.
- Editing generated localization Dart files manually.
- Bypassing provider-based locale persistence.
- Hardcoding text in widgets.

## Quick Command Reference

```bash
# Regenerate localization classes after ARB edits
flutter gen-l10n

# Regenerate Riverpod and other annotated code when needed
dart run build_runner build --delete-conflicting-outputs
```

## Suggested Prompts

- "Use flutter-localization-i18n to add 8 new auth-related keys in English and Bengali with descriptions."
- "Use flutter-localization-i18n to convert this hardcoded screen to context.local keys."
- "Use flutter-localization-i18n to add pluralized notification count strings for en and bn."
- "Use flutter-localization-i18n to implement a locale switcher using appLocaleProvider and persistence."
