---
name: flutter-app-infrastructure
description: "Guides Flutter app infrastructure implementation including navigation with go_router, localization with ARB files, local storage with SharedPreferences, and API integration with service layer pattern. Use when configuring navigation, adding routes, implementing deep links, setting up localization, adding translatable strings, managing local storage with SharedPreferences, integrating HTTP APIs, creating service classes, or setting up app-wide infrastructure in a Riverpod-based Flutter project."
---

# Flutter App Infrastructure

You are an **App Infrastructure Expert** for Flutter projects using Riverpod. Your job is to guide the implementation of navigation, localization, local storage, and API integration following consistent architectural patterns.

---

## 1 — Navigation (go_router + Riverpod)

Routing details are now maintained in the standalone canonical routing skill:

- **`.github/skills/flutter-routing-go-router/SKILL.md`**

Use that skill for route ownership, redirect state machine behavior, auth back-intent replay, deep-link canonicalization, session coupling (Firebase/REST), testing matrix, and routing anti-patterns.

### Concise infrastructure summary

- Keep router ownership centralized in a Riverpod-managed `GoRouter` provider consumed by `MaterialApp.router`.
- Drive redirect reevaluation through a session-driven `refreshListenable`/auth-stream trigger.
- Canonicalize incoming locations before auth guard decisions.
- Preserve unknown routes for router error rendering instead of force-rewriting them.
- Keep navigation on go_router APIs (`context.go/push/pop`) and avoid `Navigator.push` for app routing.
- App-links lifecycle orchestration is not the canonical routing approach for this repository.

---

## 2 — Localization (ARB + gen-l10n)

Localization is a core infrastructure concern because it touches app bootstrap, generated artifacts, and global app configuration.

Detailed localization workflows are maintained in **`.github/skills/flutter-localization-i18n/SKILL.md`** and should be treated as the canonical source for ARB authoring, placeholders/plurals, generation commands, and locale-switching UX patterns.

### Infrastructure Integration Expectations

- Keep `MaterialApp`/`MaterialApp.router` wired to generated localization APIs (`localizationsDelegates`, `supportedLocales`, and `locale` from provider-managed state when runtime language switching is enabled).
- Manage locale state through Riverpod providers (with persistence through approved storage providers), not ad-hoc widget state.
- Treat localization inputs/outputs with clear ownership: ARB source files are authored by developers, while generated localization Dart files are read-only and never edited manually.

---

## 3 — Local Storage (SharedPreferences + Riverpod)

### Initialization Pattern

Initialize SharedPreferences **before** `runApp` and inject via `ProviderScope.overrides`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Provider Definition

The provider throws by design — it **must** be overridden in `main.dart`:

```dart
@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(); // Only accessed via override
}
```

### Feature Provider Pattern

Never access SharedPreferences directly in widgets. Create typed feature providers:

```dart
@riverpod
class ThemeMode extends _$ThemeMode {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final value = prefs.getString(_key) ?? 'system';
    return ThemeMode.values.firstWhere((e) => e.name == value);
  }

  void setTheme(ThemeMode mode) {
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = mode;
  }
}
```

### Local Storage Anti-Patterns

- **Never call `SharedPreferences.getInstance()` directly** — always use the provider
- **Never read SharedPreferences in widget `build()` methods** — wrap access in feature providers that expose typed state
- **Don't store sensitive data in SharedPreferences** — use `flutter_secure_storage` for tokens, passwords, and secrets

---

## 4 — API Integration (Service Layer + Riverpod)

### Architecture Overview

```
Widget (UI) → Controller (state) → Service (API) → HTTP Client (Dio)
```

- **Services** — Plain Dart classes that make HTTP calls
- **Controllers** — Riverpod `AsyncNotifier` providers managing UI state
- **HTTP Client** — Injected via Riverpod provider

### HTTP Client Provider

```dart
@riverpod
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://api.example.com'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  // Add interceptors (auth, logging, etc.)
  dio.interceptors.add(LogInterceptor());
  return dio;
}
```

### Service Pattern

Services are plain Dart classes exposed as Riverpod providers. They receive the HTTP client via constructor injection:

```dart
@riverpod
UserService userService(Ref ref) {
  final dio = ref.read(dioProvider);
  return UserService(dio);
}

class UserService {
  const UserService(this._dio);
  final Dio _dio;

  Future<User> fetchUser(String id) async {
    final response = await _dio.get('/users/$id');
    return User.fromJson(response.data);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _dio.put('/users/$id', data: data);
  }
}
```

### Controller Pattern

Controllers manage async state. They call services and wrap results with `AsyncValue.guard`:

```dart
@riverpod
class UserController extends _$UserController {
  @override
  FutureOr<void> build() {}

  Future<void> loadUser(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userServiceProvider).fetchUser(id),
    );
  }
}
```

### Error Handling

Services throw typed exceptions. Controllers catch them via `AsyncValue.guard`, producing `AsyncError`. The UI reacts accordingly:

```dart
// In service — throw typed exceptions
Future<void> login(String email, String password) async {
  final response = await _dio.post('/auth/login', data: { ... });
  if (response.statusCode != 200) {
    throw AuthException('Invalid credentials');
  }
}

// In UI — react to error state
final state = ref.watch(loginControllerProvider);
state.whenOrNull(
  error: (error, _) => showErrorSnackBar(context, error.toString()),
);
```

### API Anti-Patterns

- **Don't make HTTP calls in controllers** — route all API calls through service classes
- **Don't use HTTP client directly in widget code** — isolate in the `service/` layer
- **Don't hardcode base URLs** — configure via environment variables or a provider
- **Don't store auth tokens in SharedPreferences** — use `flutter_secure_storage` for sensitive credentials

---

## 5 — Cross-Cutting Patterns

### Provider Dependency Chain

```
sharedPreferencesProvider  ←  main.dart override
    ↓
appLocaleProvider          ←  reads shared prefs, exposes Locale
dioProvider                ←  could read auth token from secure storage
    ↓
featureServiceProvider     ←  injects Dio
    ↓
featureControllerProvider  ←  reads service, manages AsyncValue state
    ↓
Widget                     ←  watches controller
```

### File Organization

```
lib/
├── core/
│   ├── router/
│   │   ├── router.dart          # GoRouter provider
│   │   └── route_utils.dart     # Query param helpers
│   ├── providers/
│   │   └── app_locale_provider.dart
│   ├── utils/
│   │   └── local_storage/
│   │       └── shared_preference_provider.dart
│   └── network/
│       └── dio_provider.dart
├── features/
│   └── <feature>/
│       ├── screens/
│       ├── controllers/
│       ├── service/
│       └── widgets/
├── l10n/
│   ├── app_en.arb
│   └── app_<locale>.arb
└── main.dart
```

### Initialization Checklist (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Local storage
  final prefs = await SharedPreferences.getInstance();

  // 2. Other async init (Firebase, etc.)
  // await Firebase.initializeApp();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 6 — Common Anti-Patterns Summary

| Area           | Don't                                        | Do                                                     |
| -------------- | -------------------------------------------- | ------------------------------------------------------ |
| Navigation     | `Navigator.push(...)` or hardcoded strings   | `context.push(Screen.route)` via go_router             |
| Localization   | Hardcode UI strings or edit generated files  | `context.local.key` + ARB workflow                     |
| Local Storage  | `SharedPreferences.getInstance()` in widgets | Feature providers wrapping `sharedPreferencesProvider` |
| API            | HTTP calls in controllers or widgets         | Service layer with Dio injected via Riverpod           |
| Auth Tokens    | Plain SharedPreferences                      | `flutter_secure_storage`                               |
| Complex Params | Serialize objects into route query strings   | Share via Riverpod providers                           |

---

## Related Skills

- **flutter-localization-i18n** — For complete localization workflow and ARB/gen-l10n implementation details
- **widget-creation** — For creating new widgets following project conventions
- **widget-reuse** — For finding existing reusable widgets before creating new ones
- **component-wiki** — For the design system component reference
