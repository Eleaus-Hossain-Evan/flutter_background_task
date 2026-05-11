---
name: flutter-testing-patterns
description: "Guides testing Flutter apps using Riverpod, flutter_hooks, and flutter_screenutil. Covers widget tests with ProviderScope overrides, controller unit tests with ProviderContainer, service mocking with mocktail, async state transition testing (loading/data/error), ScreenUtilInit wrapping, go_router navigation testing, and CI-friendly configuration. Use when writing unit tests, widget tests, integration tests, setting up test infrastructure, or debugging test failures."
---

# Flutter Testing Patterns

You are a **Flutter Testing Expert**. Your job is to write correct, maintainable tests for Flutter applications using **Riverpod**, **flutter_hooks**, and **flutter_screenutil**.

---

## Testing Decision Tree

```
What are you testing?
├── Pure business logic (no UI)
│   └── Unit test with ProviderContainer
├── Provider/controller state transitions
│   └── Unit test with ProviderContainer + container.listen
├── Widget renders correctly with given state
│   └── Widget test with ProviderScope + overrides
├── Widget responds to user interaction
│   └── Widget test with ProviderScope + tester.tap/enterText
├── Navigation flow
│   └── Widget test with GoRouter mock or integration test
├── Full user journey across screens
│   └── Integration test with patrol or integration_test
└── Visual correctness
    └── Golden test with ProviderScope + matchesGoldenFile
```

### What NOT to test

- Generated code (`.g.dart`, `.freezed.dart`)
- Framework internals (Flutter rendering, Riverpod's own logic)
- Third-party package behavior
- Hook internals — test the widget output, not the hook

---

## Test File Organization

```
test/
├── unit/<feature>/controller/  # Controller/notifier unit tests
├── unit/<feature>/service/     # Service unit tests
├── widget/<feature>/           # Widget tests per feature
├── widget/core/components/     # Shared component widget tests
├── integration/                # Full flow integration tests
└── helpers/                    # pump_app.dart, mocks.dart, test_providers.dart
```

**Naming:** files `<source>_test.dart`, groups `group('Feature -', () {})`, descriptions `'should X when Y'`

---

## Key Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  golden_toolkit: ^0.15.0        # Optional, for golden tests
```

Use **mocktail** (not mockito) — it requires no code generation and works cleanly with Riverpod.

---

## Test Helpers

### Shared `pumpApp` Helper

Every widget test that uses ScreenUtil or Riverpod should use a shared helper:

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Pumps a widget wrapped with ProviderScope and ScreenUtilInit.
///
/// Use [overrides] to mock providers. All widget tests should use this.
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(home: widget),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

### Shared Mock Classes

```dart
// test/helpers/mocks.dart
import 'package:mocktail/mocktail.dart';

// Define mocks for your service interfaces
class MockAuthService extends Mock implements AuthService {}
class MockUserRepository extends Mock implements UserRepository {}
class MockGoRouter extends Mock implements GoRouter {}
```

---

## Pattern 1 — Controller Unit Test with ProviderContainer

Test async controllers (Notifiers) that use `AsyncValue.guard()` for state transitions.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockItemService extends Mock implements ItemService {}

void main() {
  late MockItemService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockItemService();
    container = ProviderContainer.test(
      overrides: [
        // Override the service provider, not the controller itself
        itemServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  group('ItemController -', () {
    test('should emit loading then data on successful fetch', () async {
      // Arrange
      final items = [Item(id: '1', name: 'Test')];
      when(() => mockService.fetchItems()).thenAnswer((_) async => items);

      // Act — listen to capture state transitions
      final states = <AsyncValue<List<Item>>>[];
      container.listen(
        itemControllerProvider,
        (prev, next) => states.add(next),
        fireImmediately: true,
      );

      // Wait for async initialization
      await container.read(itemControllerProvider.future);

      // Assert — verify state transitions
      expect(states, [
        const AsyncLoading<List<Item>>(),
        AsyncData<List<Item>>(items),
      ]);
      verify(() => mockService.fetchItems()).called(1);
    });

    test('should emit loading then error on failure', () async {
      // Arrange
      when(() => mockService.fetchItems())
          .thenThrow(Exception('Network error'));

      // Act
      final states = <AsyncValue<List<Item>>>[];
      container.listen(
        itemControllerProvider,
        (prev, next) => states.add(next),
        fireImmediately: true,
      );

      // Allow async error to propagate
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Assert
      expect(states.first, isA<AsyncLoading<List<Item>>>());
      expect(states.last, isA<AsyncError<List<Item>>>());
    });

    test('should call service method on action', () async {
      // Arrange
      when(() => mockService.fetchItems()).thenAnswer((_) async => []);
      when(() => mockService.deleteItem(any()))
          .thenAnswer((_) async => true);

      // Wait for init
      await container.read(itemControllerProvider.future);

      // Act
      final notifier = container.read(itemControllerProvider.notifier);
      await notifier.deleteItem('1');

      // Assert
      verify(() => mockService.deleteItem('1')).called(1);
    });
  });
}
```

### Key points:
- Use `ProviderContainer.test()` — it auto-disposes after the test
- Override at the **service provider** level, not the controller
- Use `container.listen` with `fireImmediately: true` to capture all state transitions
- Use `container.read(provider.future)` to await async providers

---

## Pattern 2 — Widget Test with Riverpod Overrides

```dart
import '../../helpers/pump_app.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockItemService mockService;
  setUp(() => mockService = MockItemService());

  group('ItemListScreen -', () {
    testWidgets('should display items when data loads', (tester) async {
      when(() => mockService.fetchItems())
          .thenAnswer((_) async => [Item(id: '1', name: 'Alpha')]);

      await pumpApp(tester, const ItemListScreen(),
          overrides: [itemServiceProvider.overrideWithValue(mockService)]);

      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      // Use a Completer to keep future pending → shows loading state
      final completer = Completer<List<Item>>();
      when(() => mockService.fetchItems())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [itemServiceProvider.overrideWithValue(mockService)],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            child: const MaterialApp(home: ItemListScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should call delete on button tap', (tester) async {
      when(() => mockService.fetchItems())
          .thenAnswer((_) async => [Item(id: '1', name: 'Alpha')]);
      when(() => mockService.deleteItem(any()))
          .thenAnswer((_) async => true);

      await pumpApp(tester, const ItemListScreen(),
          overrides: [itemServiceProvider.overrideWithValue(mockService)]);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteItem('1')).called(1);
    });
  });
}
```

---

## Pattern 3 — Testing with ScreenUtil

Widgets using `.h`, `.w`, `.sp` extensions **will crash** without `ScreenUtilInit`. Always wrap:

```dart
// Minimal ScreenUtilInit wrapper for widget tests
await tester.pumpWidget(
  ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(375, 812), // Match your app's design size
      minTextAdapt: true,
      child: MaterialApp(home: widgetUnderTest),
    ),
  ),
);
// IMPORTANT: call pumpAndSettle after ScreenUtilInit
await tester.pumpAndSettle();
```

**Common pitfall:** If you see `'ScreenUtil not initialized'` errors, you forgot to wrap with `ScreenUtilInit` or forgot `pumpAndSettle()`.

---

## Pattern 4 — Mocking Services with Mocktail

```dart
class MockAuthService extends Mock implements AuthService {}

void main() {
  // Register fallback values for custom types used with any()
  setUpAll(() => registerFallbackValue(UserCredentials(email: '', password: '')));

  late MockAuthService mockAuth;
  setUp(() => mockAuth = MockAuthService());

  test('login delegates to auth service', () async {
    when(() => mockAuth.login(any()))
        .thenAnswer((_) async => User(id: '1', name: 'Test'));

    final container = ProviderContainer.test(
      overrides: [authServiceProvider.overrideWithValue(mockAuth)],
    );
    final result = await container.read(loginControllerProvider.future);
    expect(result, isA<User>());
    verify(() => mockAuth.login(any())).called(1);
  });
}
```

**Mock hierarchy:** Mock services/repositories (YES) > Mock controllers (rarely) > Mock hooks (NEVER)

---

## Pattern 5 — Testing Navigation (go_router)

```dart
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;
  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  testWidgets('navigates to details on tap', (tester) async {
    // Option A: Wrap with InheritedGoRouter
    await pumpApp(tester,
      InheritedGoRouter(goRouter: mockRouter, child: const ItemListScreen()),
      overrides: [itemServiceProvider.overrideWithValue(mockService)]);

    // Option B: Override router provider (if GoRouter is provided via Riverpod)
    // overrides: [routerProvider.overrideWithValue(mockRouter)]

    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    verify(() => mockRouter.push('/items/1')).called(1);
  });
}
```

---

## Pattern 6 — Testing Hooks-Based Widgets

Do **not** test hooks directly. Test the widget's rendered output:

```dart
testWidgets('HookWidget updates on interaction', (tester) async {
  await pumpApp(tester, const CounterWidget(initialValue: 0));
  expect(find.text('Count: 0'), findsOneWidget);
  await tester.tap(find.byType(CounterWidget));
  await tester.pump();
  expect(find.text('Count: 1'), findsOneWidget);
});

// For HookConsumerWidget, override providers as usual:
testWidgets('HookConsumerWidget shows provider data', (tester) async {
  await pumpApp(tester, const ProfileScreen(),
      overrides: [userProvider.overrideWith((ref) => User(name: 'Test User'))]);
  expect(find.text('Test User'), findsOneWidget);
});
```

---

## Pattern 7 — Testing SharedPreferences

```dart
setUp(() {
  // MUST call before any test that uses SharedPreferences
  SharedPreferences.setMockInitialValues({'auth_token': 'mock-token-123', 'onboarding_complete': true});
});

test('reads stored preferences', () async {
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('auth_token'), 'mock-token-123');
});
```

---

## Pattern 8 — Golden Tests

```dart
void main() {
  testGoldens('ItemCard matches golden', (tester) async {
    await loadAppFonts(); // Required for consistent text rendering
    await pumpApp(tester, const ItemCard(title: 'Test', subtitle: 'Desc'));
    await expectLater(find.byType(ItemCard), matchesGoldenFile('goldens/item_card.png'));
  });
}
```

Update goldens: `flutter test --update-goldens`

---

## Pattern 9 — Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full login flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

---

## CI-Friendly Test Configuration

```bash
flutter test --coverage --reporter expanded       # All tests
flutter test test/unit/                            # Unit only
flutter test test/widget/                          # Widget only
flutter test --exclude-tags golden                 # Skip goldens in CI
```

Tag golden tests with `@Tags(['golden'])` so they can be excluded in CI (font rendering varies across platforms). Exclude generated code in `analysis_options.yaml`:

```yaml
analyzer:
  exclude: ["**/*.g.dart", "**/*.freezed.dart"]
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Do This Instead |
|---|---|---|
| Testing without `ProviderScope` | Riverpod providers won't resolve | Always wrap with `ProviderScope` |
| Forgetting `ScreenUtilInit` | `.w/.h/.sp` extensions crash | Use shared `pumpApp` helper |
| Mocking controllers directly | Fragile, breaks encapsulation | Mock the services they depend on |
| Testing generated code | Waste of time, code-gen is trusted | Test your logic that uses generated code |
| Mocking too deeply | Internal implementation coupling | Mock at the service/repository boundary |
| Sharing `ProviderContainer` between tests | State leaks between tests | Create new container per test in `setUp` |
| Using `container.read` without `listen` | Provider may auto-dispose mid-test | Use `container.listen` + `subscription.read()` |
| Not awaiting async providers | Test completes before state resolves | Use `await container.read(provider.future)` |
| Hardcoding `ScreenUtilInit` design size differently than app | Dimensions won't match | Use same `designSize` as app's `ScreenUtilInit` |
| Testing hook internals | Hooks are implementation details | Test widget output and behavior |
| Not calling `registerFallbackValue` | Mocktail fails on custom arg types | Call in `setUpAll` for every custom type |

---

## Quick Reference

| Test Type | When | Key Setup |
|---|---|---|
| Unit (provider) | Business logic, state transitions | `ProviderContainer.test()` + `overrides` |
| Widget | UI rendering, user interaction | `ProviderScope` + `ScreenUtilInit` + `overrides` |
| Golden | Visual regression | `loadAppFonts()` + `matchesGoldenFile` |
| Integration | Full user flows | `IntegrationTestWidgetsFlutterBinding` |

| Mock Target | Tool | Example |
|---|---|---|
| Service/Repository | `mocktail` | `class MockAuthService extends Mock implements AuthService {}` |
| Provider value | Riverpod override | `provider.overrideWithValue(mockValue)` |
| Provider factory | Riverpod override | `provider.overrideWith((ref) => value)` |
| SharedPreferences | Built-in | `SharedPreferences.setMockInitialValues({})` |
| GoRouter | `mocktail` | `class MockGoRouter extends Mock implements GoRouter {}` |
