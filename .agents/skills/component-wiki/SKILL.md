---
name: component-wiki
description: "Provides comprehensive documentation and usage examples for all reusable widgets in core/components/ and feature widgets. Use this skill to look up widget APIs, find usage examples, understand widget parameters, or discover available UI components in the Appeler design system."
---

# Component Wiki

You are the **Component Documentation Expert** for the Appeler Flutter project. Your job is to provide **detailed documentation, usage examples, and API references** for all reusable widgets.

## Primary Objective

When the user asks about a widget or component category:

1. **Provide complete API documentation** with all parameters
2. **Show multiple usage examples** from simple to advanced
3. **Explain design decisions** and when to use each widget
4. **Link to related widgets** for alternative approaches

---

## Component Inventory

### Buttons

#### `CustomButton` (Preferred)

**Location:** `lib/core/components/custom_button.dart`
**Import:** `package:appeler/core/core.dart`

Modern universal button with type and variant system.

**Factory Constructors:**

```dart
// Primary filled button (default CTA)
CustomButton.primary(
  text: 'Sign In',
  onPressed: () {},
  isLoading: false,
  leadingIcon: Icon(Icons.login),
  trailingIcon: Icon(UIIcons.rightarrow, size: 18),
)

// Outlined secondary button
CustomButton.outlined(
  text: 'Cancel',
  onPressed: () {},
)

// Text button (link style)
CustomButton.textButton(
  text: 'Forgot Password?',
  onPressed: () {},
  fontColor: AppColors.primary,
  fontSize: 14.sp,
  fontWeight: FontWeight.w500,
)

// Elevated with shadow
CustomButton.elevated(
  text: 'Continue',
  onPressed: () {},
)

// Destructive action (delete, remove)
CustomButton.destructive(
  text: 'Delete Account',
  onPressed: () {},
  isLoading: isDeleting,
)
```

**Key Parameters:**

- `text` (String) — Button label
- `onPressed` (VoidCallback?) — Tap handler (null = disabled)
- `isLoading` (bool) — Shows spinner, disables button
- `leadingIcon` / `trailingIcon` (Widget?) — Optional icons
- `fontColor`, `fontSize`, `fontWeight` — Text styling
- `width`, `height` — Dimensions
- `borderRadius` — Corner radius

**Type System:**

- `AppButtonType.filled` — Solid background
- `AppButtonType.outlined` — Border only
- `AppButtonType.elevated` — With shadow
- `AppButtonType.text` — No background/border

**Variant System:**

- `AppButtonVariant.primary` — Primary brand color
- `AppButtonVariant.secondary` — Secondary/neutral
- `AppButtonVariant.destructive` — Danger/delete red
- `AppButtonVariant.success` — Success green

---

#### `AppButton` (Legacy)

**Location:** `lib/core/components/app_button.dart`

Lower-level MaterialButton wrapper. Use `CustomButton` for new code.

```dart
AppButton.filled(
  text: 'Submit',
  onPressed: () {},
  loading: isLoading,
  icon: Icon(Icons.send),
  color: AppColors.primary,
  height: 48,
)

AppButton.filledSecondary(
  text: 'Cancel',
  onPressed: () {},
)
```

---

### Form Fields

#### `TitleTextFormField` (Default Choice)

**Location:** `lib/core/components/title_text_form_field.dart`

Labeled text input combining title + `CustomTextFormField`.

```dart
TitleTextFormField(
  controller: nameController,
  title: 'Full Name',
  hintText: 'Enter your name',
  validator: (v) => AppValidators.requiredField(v, fieldName: 'Name'),
  keyboardType: TextInputType.name,
  textInputAction: TextInputAction.next,
)
```

---

#### `CustomTextFormField`

**Location:** `lib/core/components/custom_text_form_field.dart`

Full-featured text input with extensive customization.

```dart
// Basic
CustomTextFormField(
  controller: controller,
  hintText: 'Enter value',
  validator: AppValidators.email,
)

// Password with auto eye toggle
CustomTextFormField(
  controller: passwordController,
  hintText: 'Password',
  isObscure: true,  // Auto-adds visibility toggle
)

// With icons
CustomTextFormField(
  controller: searchController,
  hintText: 'Search...',
  prefixIcon: Icon(Icons.search),
  suffixIcon: Icon(Icons.clear),
)

// Date picker factory
CustomTextFormField.date(
  controller: dateController,
  labelText: 'Date of Birth',
  hintText: 'Select date',
  onChanged: (value) {},
)
```

**Key Parameters:**

- `isObscure` — Password mode with toggle
- `readOnly` — Disable editing
- `prefixIcon` / `suffixIcon` — Field icons
- `validator` — Form validation
- `fillColor` / `borderColor` — Styling
- `focusNode` — Focus control
- `onChanged` / `onFieldSubmitted` — Callbacks

---

#### `TitleDateFormField`

**Location:** `lib/core/components/title_date_form_field.dart`

Labeled date picker field.

```dart
TitleDateFormField(
  controller: dobController,
  title: 'Date of Birth',
  hintText: 'MM/DD/YYYY',
  validator: (v) => AppValidators.requiredField(v, fieldName: 'DOB'),
  onChanged: (date) => print('Selected: $date'),
)
```

---

#### `CountryPhoneInputField`

**Location:** `lib/core/components/country_phone_input_field.dart`
**Import:** Direct import required (not in barrel)

```dart
import 'package:appeler/core/components/country_phone_input_field.dart';

CountryPhoneInputField(
  controller: phoneController,
  focusNode: phoneFocusNode,
  hintText: 'Enter phone number',
  validator: AppValidators.phone,
  onCountryChanged: (country) {
    print('Country code: ${country.dialCode}');
  },
)
```

---

### Selection & Pickers

#### `TitleSelectionFormField<T>`

**Location:** `lib/features/auth/widgets/title_selection_form_field.dart`

Generic bottom-sheet selector with form validation.

```dart
// Simple string selection
TitleSelectionFormField<String>(
  title: 'Country',
  hintText: 'Select country',
  value: selectedCountry,
  items: const ['USA', 'Bangladesh', 'India'],
  displayStringForItem: (item) => item,
  onChanged: (value) => setState(() => selectedCountry = value),
  validator: (v) => v == null ? 'Required' : null,
)

// Custom model with leading icon
TitleSelectionFormField<Gender>(
  title: 'Gender',
  hintText: 'Select gender',
  value: selectedGender,
  items: Gender.values,
  displayStringForItem: (g) => g.label,
  leadingBuilder: (g) => Icon(g.icon),
  onChanged: (value) => setState(() => selectedGender = value),
)

// Fully custom item builder
TitleSelectionFormField<User>(
  title: 'Assign To',
  hintText: 'Select user',
  value: selectedUser,
  items: users,
  displayStringForItem: (u) => u.name,
  itemBuilder: (context, user, isSelected, onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: SelectionRadio(isSelected: isSelected),
      onTap: onTap,
    );
  },
  onChanged: (value) => setState(() => selectedUser = value),
)
```

---

#### `SelectionRadio`

**Location:** `lib/features/auth/widgets/selection_radio.dart`

Radio indicator widget for custom selection lists.

```dart
SelectionRadio(isSelected: isItemSelected)
```

---

#### `AuthTypeSwitcher`

**Location:** `lib/core/components/auth_type_switcher.dart`

Phone/Email toggle with animated input switching.

```dart
AuthTypeSwitcher(
  phoneOrEmailController: credentialController,
  inputFocusNode: inputFocus,
  initialValue: AuthInputType.phone,
  onTabChanged: (type) {
    // AuthInputType.phone or AuthInputType.email
    setState(() => currentType = type);
  },
)
```

---

### Typography

#### `AppText`

**Location:** `lib/core/components/app_text.dart`

Pre-styled text with Poppins font and color variants.

```dart
// Basic
AppText('Hello World', fontSize: 14.sp)

// Color variants
AppText.primary('Primary colored')
AppText.white('White text')
AppText.neutral700('Gray text')
AppText.neutral600('Lighter gray')

// Full customization
AppText(
  'Custom styled text',
  fontSize: 16.sp,
  fontWeight: FontWeight.w600,
  color: AppColors.black,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
)
```

---

### Form Controls

#### `AppCheckbox`

**Location:** `lib/core/components/app_checkbox.dart`
**Import:** `package:appeler/core/core.dart`

Custom animated checkbox with brand styling.

```dart
// Basic usage
AppCheckbox(
  value: isChecked,
  onChanged: (newValue) => setState(() => isChecked = newValue ?? false),
)

// Read-only (no interaction)
AppCheckbox(
  value: true,
  onChanged: null,  // Disables interaction
)

// In a form
Row(
  children: [
    AppCheckbox(
      value: agreedToTerms,
      onChanged: (value) => setState(() => agreedToTerms = value ?? false),
    ),
    SizedBox(width: 8.w),
    Expanded(
      child: AppText('I agree to the Terms and Conditions', fontSize: 13.sp),
    ),
  ],
)
```

**Parameters:**

- `value` (bool, required) — Checkbox state
- `onChanged` (ValueChanged<bool?>?) — State change callback (null = disabled)

---

#### `AppCheckboxTile`

**Location:** `lib/core/components/app_checkbox_tile.dart`
**Import:** `package:appeler/core/core.dart`

Checkbox with accompanying text label. Combines `AppCheckbox` + `AppText` in a tappable row.

```dart
// Basic usage
AppCheckboxTile(
  text: 'Remember me',
  value: rememberMe,
  onChanged: (newValue) => setState(() => rememberMe = newValue ?? false),
)

// Multiple checkboxes with spacing
Column(
  children: [
    AppCheckboxTile(
      text: 'Email notifications',
      value: emailNotifications,
      onChanged: (value) => setState(() => emailNotifications = value ?? false),
    ),
    AppSpace.v8,
    AppCheckboxTile(
      text: 'SMS notifications',
      value: smsNotifications,
      onChanged: (value) => setState(() => smsNotifications = value ?? false),
    ),
  ],
)
```

**Parameters:**

- `text` (String, required) — Label text
- `value` (bool, required) — Checkbox state
- `onChanged` (ValueChanged<bool?>, required) — State change callback

---

### Navigation & Layout

#### `AppBarWithOnlyBackButton`

```dart
Scaffold(
  appBar: const AppBarWithOnlyBackButton(),
  body: // ...
)
```

#### `AppBarBackButton`

```dart
AppBar(
  leading: const AppBarBackButton(),
  title: Text('Custom Title'),
)
```

#### `FooterDeclaration`

```dart
Scaffold(
  body: // ...
  bottomNavigationBar: const FooterDeclaration(
    brightness: Brightness.light,  // or .dark
  ),
)
```

#### `RegistrationSectionHeader`

**Location:** `lib/features/auth/widgets/registration_section_header.dart`

```dart
RegistrationSectionHeader(title: 'Personal Information')
```

---

## Quick Lookup Table

| Need                  | Widget                       | Factory/Constructor            |
| --------------------- | ---------------------------- | ------------------------------ |
| Primary CTA button    | `CustomButton`               | `.primary()`                   |
| Secondary button      | `CustomButton`               | `.outlined()`                  |
| Text link             | `CustomButton`               | `.textButton()`                |
| Delete/danger         | `CustomButton`               | `.destructive()`               |
| Labeled text input    | `TitleTextFormField`         | Constructor                    |
| Password input        | `CustomTextFormField`        | `isObscure: true`              |
| Date picker           | `TitleDateFormField`         | Constructor                    |
| Phone + country       | `CountryPhoneInputField`     | Constructor                    |
| Bottom sheet selector | `TitleSelectionFormField<T>` | Constructor                    |
| Phone/email toggle    | `AuthTypeSwitcher`           | Constructor                    |
| Checkbox              | `AppCheckbox`                | Constructor                    |
| Checkbox with label   | `AppCheckboxTile`            | Constructor                    |
| Styled text           | `AppText`                    | `.primary()`, `.white()`, etc. |
| Back app bar          | `AppBarWithOnlyBackButton`   | `const`                        |
| Footer                | `FooterDeclaration`          | `const`                        |
| Section divider       | `RegistrationSectionHeader`  | Constructor                    |

---

## Import Paths

| Widget                   | Import                                           |
| ------------------------ | ------------------------------------------------ |
| Most widgets             | `core/core.dart` (barrel)                        |
| `AuthToggleTabs`         | `core/components/auth_toggle_tabs.dart`          |
| `CountryPhoneInputField` | `core/components/country_phone_input_field.dart` |
| Feature widgets          | `features/<name>/widgets/<widget>.dart`          |

---

## Response Format

When documenting a widget, provide:

1. **Location & Import**
2. **Purpose** (one sentence)
3. **Basic Example**
4. **Advanced Examples** (2-3 variations)
5. **Key Parameters** (table or list)
6. **Related Widgets** (alternatives or companions)
