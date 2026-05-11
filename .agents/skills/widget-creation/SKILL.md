---
name: widget-creation
description: "Guides the creation of new Flutter widgets following Appeler architecture patterns. Determines optimal placement (feature-level vs global), generates properly structured widget code with documentation, ensures design system compliance, and handles barrel exports. Use this skill AFTER confirming no existing widget fits your needs via the widget-reuse skill."
---

# Widget Creation Guide

You are a **Widget Architecture Expert** for the Appeler Flutter project. Your job is to **create new widgets** that follow project conventions, ensure proper placement, and maintain design system consistency.

## Primary Objective

When creating a new widget:

1. **Determine optimal placement** — Feature-local vs global
2. **Generate properly structured code** — With documentation and examples
3. **Ensure design system compliance** — Use AppColors, AppTextStyles, screenutil
4. **Handle exports** — Update barrel files if needed
5. **Provide usage example** — Ready-to-use code

---

## Step 1 — Placement Decision

### Place in `lib/core/components/` (Global) When:

- Used by **2+ features**
- Generic enough to work in any context
- Part of the design system (buttons, inputs, typography)
- App-wide structural widgets (app bars, footers)

**After adding:**

1. Create file in `lib/core/components/<widget_name>.dart`
2. Add export to `lib/core/components/components.dart`

### Place in `lib/features/<name>/widgets/` (Feature-Local) When:

- Only used within **one feature**
- Contains feature-specific domain logic
- Not generic enough for other features
- May be promoted to global later

**After adding:**

1. Create file in `lib/features/<feature>/widgets/<widget_name>.dart`
2. Import directly where needed

---

## Step 2 — Widget Structure Template

### StatelessWidget (Default)

````dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appeler/core/core.dart';

/// Brief one-line description of the widget.
///
/// Use this widget when [describe use case].
///
/// ## Example
///
/// ```dart
/// WidgetName(
///   title: 'Example',
///   onTap: () => print('tapped'),
/// )
/// ```
///
/// ## Example with optional parameters
///
/// ```dart
/// WidgetName(
///   title: 'Advanced',
///   subtitle: 'With subtitle',
///   leading: Icon(Icons.person),
///   onTap: () {},
/// )
/// ```
///
/// See also:
/// - [RelatedWidget], for alternative approach.
class WidgetName extends StatelessWidget {
  /// Creates a [WidgetName].
  const WidgetName({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  /// The primary text displayed in the widget.
  final String title;

  /// Optional secondary text below the title.
  final String? subtitle;

  /// Optional widget displayed before the title.
  final Widget? leading;

  /// Called when the widget is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              12.horizontalSpace,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  if (subtitle != null) ...[
                    4.verticalSpace,
                    AppText(
                      subtitle!,
                      fontSize: 14.sp,
                      color: AppColors.neutral600,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

### HookWidget (With Local State)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appeler/core/core.dart';

/// Widget with local state using hooks.
class StatefulWidgetName extends HookWidget {
  const StatefulWidgetName({
    super.key,
    required this.initialValue,
    this.onChanged,
  });

  final int initialValue;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final count = useState(initialValue);

    return GestureDetector(
      onTap: () {
        count.value++;
        onChanged?.call(count.value);
      },
      child: AppText(
        'Count: ${count.value}',
        fontSize: 16.sp,
      ),
    );
  }
}
```

### HookConsumerWidget (With Riverpod)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appeler/core/core.dart';

/// Widget with hooks and Riverpod provider access.
class ProviderWidgetName extends HookConsumerWidget {
  const ProviderWidgetName({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final someState = ref.watch(someProvider);

    return Column(
      children: [
        CustomTextFormField(
          controller: controller,
          hintText: 'Enter value',
        ),
        AppSpace.v4,
        someState.when(
          data: (data) => AppText('Data: $data'),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => AppText.primary('Error: $e'),
        ),
      ],
    );
  }
}
```

---

## Step 3 — Design System Compliance

### Colors — Always use `AppColors`

```dart
// Correct
color: AppColors.primary500
borderColor: AppColors.neutral300
backgroundColor: AppColors.white

// Never
color: Color(0xFFF43023)
color: Colors.red
```

### Typography — Always use `AppText` or `AppTextStyles`

```dart
// Correct
AppText('Title', fontSize: 16.sp, fontWeight: FontWeight.w600)
AppTextStyles.bodyMD.semiBold.colorSet(AppColors.black)

// Never
Text('Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
```

### Dimensions — Always use `flutter_screenutil`

```dart
// Correct
padding: EdgeInsets.all(16.w)
fontSize: 14.sp
height: 48.h
SizedBox(height: 12.h)
12.verticalSpace
24.horizontalSpace

// Never
padding: EdgeInsets.all(16)
fontSize: 14
```

### Spacing — Use `AppSpace` for standard spacing

```dart
// Correct
AppSpace.v4   // SizedBox(height: 16.h)
AppSpace.h4   // SizedBox(width: 16.w)
AppSpace.pagePadding  // EdgeInsets.all(16)

// Also acceptable for custom values
16.verticalSpace
24.horizontalSpace
```

### Strings — Use localization

```dart
// Correct
context.local.submit
context.local.cancel

// Never (for user-facing text)
'Submit'
'Cancel'
```

---

## Step 4 — Documentation Requirements

Every widget must have:

### 1. Class-Level Doc Comment

````dart
/// Brief description (one line).
///
/// Longer explanation of when and how to use this widget.
///
/// ## Example
/// ```dart
/// WidgetName(property: value)
/// ```
````

### 2. Parameter Documentation (for non-obvious params)

```dart
/// The callback invoked when selection changes.
///
/// If null, the widget will be non-interactive.
final ValueChanged<T>? onChanged;
```

### 3. See Also References

```dart
/// See also:
/// - [AlternativeWidget], for a different approach.
/// - [RelatedWidget], often used together.
```

---

## Step 5 — Naming Conventions

| Pattern           | Example                     | When to Use           |
| ----------------- | --------------------------- | --------------------- |
| `<Name>`          | `ProfileCard`               | Simple widgets        |
| `<Name>Button`    | `SubmitButton`              | Button variants       |
| `<Name>FormField` | `TitleTextFormField`        | Form inputs           |
| `<Context><Name>` | `RegistrationSectionHeader` | Context-specific      |
| `<Name>Tile`      | `DriverTile`                | List item widgets     |
| `<Name>Card`      | `TripCard`                  | Card-style containers |

---

## Step 6 — Generic Widgets

For widgets that work with multiple types:

````dart
/// A selection field that works with any item type.
///
/// ## Example with String
/// ```dart
/// SelectionField<String>(
///   items: ['A', 'B', 'C'],
///   displayStringForItem: (item) => item,
/// )
/// ```
///
/// ## Example with custom model
/// ```dart
/// SelectionField<User>(
///   items: users,
///   displayStringForItem: (user) => user.name,
/// )
/// ```
class SelectionField<T> extends StatelessWidget {
  const SelectionField({
    super.key,
    required this.items,
    required this.displayStringForItem,
    this.onChanged,
  });

  final List<T> items;
  final String Function(T) displayStringForItem;
  final ValueChanged<T>? onChanged;

  // ...
}
````

---

## Step 7 — Update Barrel Exports (Global Only)

If adding to `core/components/`, update `components.dart`:

```dart
// lib/core/components/components.dart
export 'app_bar_back_button.dart';
export 'app_button.dart';
export 'app_text.dart';
// ... existing exports ...
export 'your_new_widget.dart';  // Add alphabetically
```

---

## Output Format

When creating a widget, provide:

1. **Placement Decision** — Where to put the widget and why
2. **Complete Widget Code** — Ready to copy
3. **Usage Example** — How to use in a screen
4. **Barrel Export Update** — If needed (for global widgets)
5. **Related Widgets** — Mention companions or alternatives

---

## Checklist Before Completion

- [ ] Used correct base class (StatelessWidget / HookWidget / HookConsumerWidget)
- [ ] All colors from `AppColors`
- [ ] All dimensions use screenutil (`.w`, `.h`, `.sp`)
- [ ] All text uses `AppText` or `AppTextStyles`
- [ ] Documentation with at least one example
- [ ] Proper file naming (`snake_case.dart`)
- [ ] Class naming (`PascalCase`)
- [ ] Barrel export updated (if global)

---

## Anti-Patterns to Avoid

- Do not use raw `Color()` values
- Do not use raw `TextStyle()` without `AppTextStyles`
- Do not use hardcoded dimensions without screenutil
- Do not create widget without documentation
- Do not place feature-specific widget in `core/components/`
- Do not forget to export global widget in barrel file
- Do not use `StatefulWidget` when `HookWidget` would suffice
