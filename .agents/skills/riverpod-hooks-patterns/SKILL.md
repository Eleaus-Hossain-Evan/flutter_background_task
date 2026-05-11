---
name: riverpod-hooks-patterns
description: "Implements state management patterns using Riverpod code generation and flutter_hooks. Covers provider types (mutation controllers, data providers, simple state), async mutation with AsyncValue.guard, typed exception handling, Flutter hooks for local state (useState, useEffect, useMemoized), and useAsyncActionFeedback for unified loading/error/success UI feedback. Use when creating providers, controllers, managing async state, handling errors, building reactive screens, wiring UI feedback, or choosing between provider types. Keywords: riverpod, provider, AsyncNotifier, AsyncValue, ref.watch, ref.read, hooks, useState, useEffect, useAsyncActionFeedback, error handling, mutation controller."
---

# Riverpod & Hooks Patterns

You are an expert in Flutter state management using **Riverpod with code generation** (`riverpod_annotation` + `riverpod_generator`) and **flutter_hooks**. Apply these patterns when creating providers, controllers, screens, or handling async state.

---

## Provider Type Decision Tree

```
Need to manage state?
├── Async action triggered by user (login, submit, delete)?
│   └── ➜ Mutation Controller (AsyncNotifier<void>)
├── Data that loads automatically on first access?
│   └── ➜ Data Provider (AsyncNotifier<T>)
├── Synchronous app-wide state (locale, theme, filters)?
│   └── ➜ Simple State Provider (Notifier<T>)
├── Derived/computed value from other providers?
│   └── ➜ Generated functional provider (@riverpod function)
└── Service or repository instance?
    └── ➜ Generated functional provider returning the instance
```

---

## Code Generation Setup

Every provider file requires:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part '<filename>.g.dart';
```

After changes, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Provider Patterns

### 1. Mutation Controller (Most Common)

For user-triggered async actions. Returns `AsyncValue<void>`:

```dart
// lib/features/<feature>/providers/<action>_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part '<action>_controller.g.dart';

@riverpod
class <FeatureName>Controller extends _$<FeatureName>Controller {
  @override
  FutureOr<void> build() {} // void initial state — no auto-fetch

  Future<void> submit({required String param}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(<serviceProvider>).<method>(param),
    );
  }
}
```

**Key points:**
- `build()` returns `FutureOr<void>` — no data to fetch on init
- `AsyncValue.guard()` wraps any thrown exception into `AsyncError`
- Always set `state = const AsyncLoading()` before the guard call
- Use `ref.read()` inside methods (not `ref.watch()`)

### 2. Data Provider (Auto-Fetching)

For data that loads on first access:

```dart
@riverpod
class <FeatureName>Data extends _$<FeatureName>Data {
  @override
  FutureOr<List<Item>> build() async {
    return await ref.read(<apiServiceProvider>).fetchItems();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(<apiServiceProvider>).fetchItems(),
    );
  }
}
```

### 3. Simple State Provider

For synchronous app-wide state:

```dart
@riverpod
class <ConceptName> extends _$<ConceptName> {
  @override
  <Type> build() {
    // Return initial value, optionally reading from persistence
    return <initialValue>;
  }

  void update(<Type> newValue) {
    state = newValue;
  }
}
```

### 4. Functional Provider (Computed / Service)

For derived values or service instances:

```dart
@riverpod
double taxRate(TaxRateRef ref) {
  final country = ref.watch(countryProvider);
  return country == 'US' ? 0.08 : 0.20;
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService(ref.read(httpClientProvider));
}
```

---

## Consuming Providers in Widgets

| Method | Use When | Example |
|--------|----------|---------|
| `ref.watch(provider)` | Rebuild on change (in `build()`) | `final state = ref.watch(myProvider);` |
| `ref.read(provider)` | One-shot read (in callbacks) | `ref.read(myProvider.notifier).submit();` |
| `ref.listen(provider, callback)` | Side effects (navigation, toasts) | Prefer `useAsyncActionFeedback` instead |

### AsyncValue Pattern in UI

```dart
final asyncData = ref.watch(dataProvider);

asyncData.when(
  data: (items) => ListView.builder(...),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

---

## File Conventions

| Scope | Location | Export |
|-------|----------|-------|
| App-wide providers | `lib/core/providers/<concept>_provider.dart` | Barrel: `core/providers/providers.dart` |
| Feature providers | `lib/features/<name>/providers/<concept>_controller.dart` | Import directly |
| Services | `lib/features/<name>/service/<name>_service.dart` | Import directly |

---

## Flutter Hooks

### Core Hooks

```dart
// Reactive local state
final count = useState(0);
final isVisible = useState(true);

// Auto-disposed controllers
final controller = useTextEditingController();
final focusNode = useFocusNode();

// Stable references across rebuilds
final formKey = useMemoized(GlobalKey<FormState>.new);

// Memoized expensive computation (recomputes when deps change)
final parsed = useMemoized(() => expensiveParse(input), [input]);

// Side effects with cleanup
useEffect(() {
  final sub = stream.listen(handleData);
  return sub.cancel; // cleanup
}, [stream]);
```

### Widget Base Classes

| Base Class | When to Use |
|------------|-------------|
| `HookConsumerWidget` | **Default** — needs hooks and/or Riverpod |
| `ConsumerWidget` | Riverpod only, no local state hooks |
| `HookWidget` | Hooks only, no Riverpod (rare) |
| `StatelessWidget` | Purely static, no reactivity |

---

## useAsyncActionFeedback — Primary Async UI Pattern

The **preferred** way to handle mutation-driven loading/error/success feedback. Replaces manual `ref.listen` boilerplate.

### Basic Usage

```dart
class MyScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAsyncActionFeedback<void>(
      ref: ref,
      provider: <featureControllerProvider>,
      onSuccess: (_) => context.go('/next-route'),
      successMessageBuilder: (_) => 'Action completed!',
      errorMessageBuilder: (e) => 'Something went wrong.',
    );

    return ElevatedButton(
      onPressed: () => ref.read(<featureControllerProvider>.notifier).submit(),
      child: const Text('Submit'),
    );
  }
}
```

### Complete Parameter Reference

| Parameter | Type | Purpose |
|-----------|------|---------|
| `ref` | `WidgetRef` | **Required** — the Riverpod ref |
| `provider` | `ProviderListenable<AsyncValue<T>>` | **Required** — the provider to listen to |
| `onSuccess` | `FutureOr<void> Function(AsyncData<T>)?` | Callback after success |
| `onError` | `FutureOr<void> Function(AsyncError<T>)?` | Callback after error |
| `successMessageBuilder` | `String? Function(AsyncData<T>)?` | Toast text (return null to suppress) |
| `errorMessageBuilder` | `String? Function(AsyncError<T>)?` | Error toast text (return null to suppress) |
| `successToastBuilder` | `void Function(AsyncData<T>)?` | Full toast control (overrides message) |
| `errorToastBuilder` | `void Function(AsyncError<T>)?` | Full toast control (overrides message) |
| `skipLoading` | `bool` | Suppress loading indicator (default: `false`) |
| `skipError` | `bool` | Suppress error toast (default: `false`) |
| `skipSuccess` | `bool` | Suppress success toast (default: `false`) |
| `closeLoadingOnDispose` | `bool` | Auto-close loading on widget disposal (default: `true`) |

### Toast Priority

1. **`*ToastBuilder`** — caller fully owns the toast presentation
2. **`*MessageBuilder`** — text-only; hook renders with default style
3. **Fallback (error only)** — `error.toString()` with default style

### Multiple Async Actions Per Screen

Use multiple hooks for screens with multiple async actions:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  useAsyncActionFeedback<void>(
    ref: ref,
    provider: resendCodeControllerProvider,
    onSuccess: (_) => timer.restart(),
  );
  useAsyncActionFeedback<void>(
    ref: ref,
    provider: verifyCodeControllerProvider,
    onSuccess: (_) => context.go('/dashboard'),
  );
  // ...
}
```

---

## Error Handling

### Layered Architecture

```
Service (throws exceptions)
  → Controller (catches with AsyncValue.guard → AsyncError)
    → UI (useAsyncActionFeedback displays error)
```

### Typed Exceptions

Create domain-specific exceptions with `toString()` override:

```dart
class <Feature>Exception implements Exception {
  const <Feature>Exception(this.message);
  final String message;

  @override
  String toString() => message; // Ensures readable error in toasts
}
```

### Controller Error Pattern

```dart
Future<void> doAction() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final result = await ref.read(<serviceProvider>).<method>();
    if (!result.success) {
      throw <Feature>Exception(result.message);
    }
    return result;
  });
}
```

### Service Layer

Services **throw** exceptions — they never catch silently:

```dart
class <Feature>Service {
  Future<void> performAction(String param) async {
    final response = await _client.post('/endpoint', body: {'param': param});
    if (response.statusCode != 200) {
      throw <Feature>Exception('Action failed: ${response.body}');
    }
  }
}
```

### UI Error Display

```dart
useAsyncActionFeedback<void>(
  ref: ref,
  provider: <controllerProvider>,
  errorMessageBuilder: (error) {
    if (error.error is <Feature>Exception) {
      return (error.error as <Feature>Exception).message;
    }
    return 'An unexpected error occurred.';
  },
  onError: (error) => debugPrint('Error: ${error.error}'),
);
```

---

## Custom Hooks

Custom hooks are **top-level functions** prefixed with `use`:

```dart
// lib/features/<feature>/widgets/use_<name>.dart
// or lib/core/utils/hooks/use_<name>.dart (if shared)

<ReturnType> use<Name>({required <ParamType> param}) {
  final state = useState(<initial>);

  useEffect(() {
    // setup logic
    return () { /* cleanup */ };
  }, [param]);

  return <ReturnType>(
    value: state.value,
    // ...
  );
}
```

**Placement:**
- Feature-local: `lib/features/<name>/widgets/use_<hook_name>.dart`
- Shared: `lib/core/utils/hooks/use_<hook_name>.dart`

---

## Complete Screen Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class <FeatureName>Screen extends HookConsumerWidget {
  const <FeatureName>Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Local state via hooks
    final controller = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // 2. Async feedback wiring
    useAsyncActionFeedback<void>(
      ref: ref,
      provider: <featureName>ControllerProvider,
      onSuccess: (_) => context.go('/next'),
      errorMessageBuilder: (e) => 'Operation failed.',
    );

    // 3. Build UI
    return Scaffold(
      body: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(controller: controller),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // 4. Trigger action via ref.read (never ref.watch in callbacks)
                  ref.read(<featureName>ControllerProvider.notifier).submit(
                    value: controller.text.trim(),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Anti-Patterns

### Riverpod
- **Don't use `StateProvider` or `StateNotifierProvider`** — use `@riverpod` annotation exclusively
- **Don't forget the `part` directive** — `build_runner` silently fails without it
- **Don't use `ref.watch()` inside callbacks** — use `ref.read()` for one-shot reads in `onPressed`, `onTap`, etc.
- **Don't access persistence providers directly in widgets** — access through feature providers

### Hooks
- **Don't call hooks conditionally** — hooks must be called in the same order every build
- **Don't use `StatefulWidget` for local state** — use `useState`, `useTextEditingController`, etc.
- **Don't use raw `ref.listen` for toast feedback** — use `useAsyncActionFeedback`
- **Don't forget `return` in `useEffect`** — always return cleanup function or `null`
- **Don't pass mutable objects as `useEffect` keys** — use primitive values or `const []`

### Error Handling
- **Don't use try-catch in screens** — let controllers + `useAsyncActionFeedback` handle it
- **Don't swallow exceptions silently** — always surface errors to the UI layer
- **Don't use generic `Exception` for domain errors** — create typed exceptions with `toString()`
- **Don't manually manage toast for errors** — use `useAsyncActionFeedback`
