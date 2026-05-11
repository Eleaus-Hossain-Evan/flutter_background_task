---
name: clean-architecture
description: "Guides Flutter project structure following clean architecture with feature-based organization, layered separation (data, domain, presentation), and Riverpod state management. Use when creating new features, adding screens or widgets or providers, deciding where new code belongs, restructuring code, setting up barrel exports, running code generation, or scaffolding a new Flutter project. Keywords: architecture, structure, feature, layer, placement, directory, barrel, scaffold, clean, domain, data, presentation, repository, usecase, entity, provider."
---

# Clean Architecture for Flutter

You are a **Clean Architecture Expert** for Flutter projects using Riverpod. Your role is to enforce layered separation of concerns, feature-first organization, and consistent code placement across the entire codebase.

---

## Directory Structure

```
lib/
├── main.dart                 ← Entry point: bootstrap, ProviderScope, MaterialApp
├── core/                     ← Shared infrastructure (NO business logic)
│   ├── core.dart             ← Barrel file — single import for all core exports
│   ├── components/           ← Reusable UI widgets shared across features
│   │   └── components.dart   ← Barrel for components
│   ├── providers/            ← App-wide Riverpod providers
│   │   └── providers.dart    ← Barrel for providers
│   ├── router/               ← Navigation setup (go_router or auto_route)
│   ├── theme/                ← Design tokens, text styles, colors, spacing
│   │   └── index.dart        ← Barrel for theme
│   └── utils/                ← Extensions, constants, helpers
│       └── index.dart        ← Barrel for utils
├── features/                 ← One folder per product feature
│   └── <feature>/
│       ├── data/             ← Data layer
│       │   ├── models/       ← DTOs, serialization models (JSON ↔ Dart)
│       │   ├── sources/      ← Remote API clients, local DB access
│       │   └── repositories/ ← Repository implementations (concrete)
│       ├── domain/           ← Domain layer (optional for simple features)
│       │   ├── entities/     ← Pure business objects (no framework imports)
│       │   ├── repositories/ ← Repository contracts (abstract classes)
│       │   └── usecases/     ← Single-responsibility business operations
│       └── presentation/     ← Presentation layer
│           ├── providers/    ← Feature-scoped Riverpod providers
│           ├── screens/      ← Full-page screen widgets
│           └── widgets/      ← Feature-local reusable widgets
├── l10n/                     ← Localization ARB source files
├── gen/                      ← ALL generated code — NEVER edit manually
└── di.dart                   ← Dependency injection setup (optional)
```

### When to Include the Domain Layer

| Scenario                                         | Include `domain/`?                                 |
| ------------------------------------------------ | -------------------------------------------------- |
| Feature has complex business rules or validation | **Yes**                                            |
| Multiple data sources feed into one repository   | **Yes**                                            |
| Feature is simple CRUD with no transformation    | **No** — use `data/` directly from `presentation/` |
| You anticipate swapping data sources later       | **Yes** — contracts decouple layers                |

> **Rule of thumb:** Start without `domain/` for simple features. Add it when business logic grows beyond trivial mapping.

---

## Layer Responsibilities

### Data Layer (`data/`)

Handles external communication and data persistence. Knows about APIs, databases, and serialization formats.

```dart
// data/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;

  const UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  UserEntity toEntity() => UserEntity(id: id, name: name, email: email);
}
```

```dart
// data/sources/user_remote_source.dart
class UserRemoteSource {
  final Dio _dio;
  UserRemoteSource(this._dio);

  Future<UserModel> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    return UserModel.fromJson(response.data);
  }
}
```

```dart
// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteSource _remoteSource;
  UserRepositoryImpl(this._remoteSource);

  @override
  Future<UserEntity> getUser(String id) async {
    final model = await _remoteSource.getUser(id);
    return model.toEntity();
  }
}
```

### Domain Layer (`domain/`)

Pure business logic. No Flutter imports, no framework dependencies.

```dart
// domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String name;
  final String email;

  const UserEntity({required this.id, required this.name, required this.email});
}
```

```dart
// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<UserEntity> getUser(String id);
}
```

```dart
// domain/usecases/get_user_usecase.dart
class GetUserUseCase {
  final UserRepository _repository;
  GetUserUseCase(this._repository);

  Future<UserEntity> call(String id) => _repository.getUser(id);
}
```

### Presentation Layer (`presentation/`)

UI and state management. Knows about Flutter and Riverpod.

```dart
// presentation/providers/user_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'user_provider.g.dart';

@riverpod
Future<UserEntity> user(UserRef ref, String id) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(id);
}
```

```dart
// presentation/screens/user_screen.dart
class UserScreen extends HookConsumerWidget {
  const UserScreen({super.key, required this.userId});
  static const String route = '/user';

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));

    return Scaffold(
      body: userAsync.when(
        data: (user) => UserProfileCard(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

---

## Dependency Flow

```
presentation → domain → data
     ↓            ↓        ↓
  Widgets     Entities   Models
  Screens     UseCases   Sources
  Providers   Contracts  Repo Impls
```

**Rules:**

- `presentation` depends on `domain` (or `data` directly if no domain layer)
- `domain` depends on nothing (pure Dart)
- `data` implements `domain` contracts
- Never import `presentation` from `data` or `domain`

---

## Placement Rules

| What you're adding             | Where it goes                                                          |
| ------------------------------ | ---------------------------------------------------------------------- |
| New product feature            | `lib/features/<feature-name>/`                                         |
| Screen                         | `lib/features/<feature>/presentation/screens/<name>_screen.dart`       |
| Feature-local widget           | `lib/features/<feature>/presentation/widgets/<widget_name>.dart`       |
| Widget used across 2+ features | `lib/core/components/<widget_name>.dart` + barrel export               |
| Feature-scoped provider        | `lib/features/<feature>/presentation/providers/<name>_provider.dart`   |
| App-wide provider              | `lib/core/providers/<name>_provider.dart` + barrel export              |
| Repository contract            | `lib/features/<feature>/domain/repositories/<name>_repository.dart`    |
| Repository implementation      | `lib/features/<feature>/data/repositories/<name>_repository_impl.dart` |
| Data model / DTO               | `lib/features/<feature>/data/models/<name>_model.dart`                 |
| Remote/local data source       | `lib/features/<feature>/data/sources/<name>_source.dart`               |
| Business entity                | `lib/features/<feature>/domain/entities/<name>_entity.dart`            |
| Use case                       | `lib/features/<feature>/domain/usecases/<name>_usecase.dart`           |
| Design token (color, spacing)  | `lib/core/theme/`                                                      |
| Utility / extension            | `lib/core/utils/`                                                      |
| New localized string           | `lib/l10n/app_en.arb` (+ other locale ARBs)                            |

---

## Barrel Files

Barrel files provide a single-import pattern for related exports. Update them whenever adding new files.

```dart
// core/core.dart — single import for all shared infrastructure
export 'components/components.dart';
export 'providers/providers.dart';
export 'theme/index.dart';
export 'utils/index.dart';
```

**Usage:** `import 'package:<app-name>/core/core.dart';`

> Keep barrel exports **alphabetically sorted**. Add new exports immediately when creating files.

---

## Widget Base Class Rules

| Base Class           | When to Use                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `HookConsumerWidget` | **Default** — needs hooks + Riverpod provider access                      |
| `ConsumerWidget`     | Needs Riverpod but no hooks                                               |
| `HookWidget`         | Needs hooks but no Riverpod                                               |
| `StatelessWidget`    | Purely static, non-reactive UI                                            |
| `StatefulWidget`     | Only when required by third-party APIs (e.g., `TickerProviderStateMixin`) |

### Screen Template

```dart
import 'package:<app-name>/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class <FeatureName>Screen extends HookConsumerWidget {
  const <FeatureName>Screen({super.key});
  static const String route = '/<feature-name>';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const SizedBox.shrink(), // TODO: implement
    );
  }
}
```

---

## Naming Conventions

| Kind        | Convention                       | Example                          |
| ----------- | -------------------------------- | -------------------------------- |
| File names  | `snake_case.dart`                | `user_repository_impl.dart`      |
| Classes     | `PascalCase`                     | `UserRepositoryImpl`             |
| Providers   | `camelCase`                      | `userRepositoryProvider`         |
| Constants   | `camelCase` or `SCREAMING_SNAKE` | `defaultTimeout`, `API_BASE_URL` |
| Route paths | `kebab-case`                     | `/user-profile`                  |
| Directories | `snake_case`                     | `data_sources/`                  |

---

## Bootstrap Invariants

These must hold true in every app entry point:

1. **Async initialization before `runApp`** — SharedPreferences, Firebase, env config
2. **`ProviderScope`** wraps the entire app with any required overrides
3. **`ScreenUtilInit`** wraps `MaterialApp` (if using flutter_screenutil)
4. **Navigation** configured via router provider (go_router / auto_route)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
```

---

## Generated Files — Never Edit

| File pattern              | Generator                                                   | Trigger            |
| ------------------------- | ----------------------------------------------------------- | ------------------ |
| `*.g.dart`                | `build_runner` + `riverpod_generator` / `json_serializable` | Annotation changes |
| `app_localizations*.dart` | `flutter gen-l10n`                                          | ARB file changes   |
| `assets.gen.dart`         | `flutter_gen_runner`                                        | Asset file changes |

### Code Generation Commands

```bash
# Riverpod / JSON / Freezed generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode (during development)
dart run build_runner watch --delete-conflicting-outputs

# Localization
flutter gen-l10n
```

> **Never hand-edit** files in `lib/gen/` or any `*.g.dart` / `*.freezed.dart` file.

---

## Adding a New Feature — Checklist

1. Create `lib/features/<feature-name>/` directory structure:
   - `presentation/screens/`, `presentation/widgets/`, `presentation/providers/`
   - `data/models/`, `data/sources/`, `data/repositories/` (as needed)
   - `domain/entities/`, `domain/repositories/`, `domain/usecases/` (if warranted)
2. Create screen extending `HookConsumerWidget` with `static const String route`
3. Create feature-scoped providers with `@riverpod` + `part '<name>_provider.g.dart'`
4. Implement data sources and repository (concrete → implements abstract contract)
5. Add localized strings to all ARB files
6. Run `dart run build_runner build --delete-conflicting-outputs`
7. Register route in the app router configuration
8. Navigate with `context.push(<FeatureName>Screen.route)` (or via named routes `context.pushNamed('<feature-name>')`)
9. Verify barrel files are updated if any shared code was added

---

## Anti-Patterns

| Anti-Pattern                             | Why It's Wrong                     | Do This Instead                                  |
| ---------------------------------------- | ---------------------------------- | ------------------------------------------------ |
| Business logic in widgets                | Breaks testability; mixes concerns | Move to use cases or providers                   |
| Repository returning Flutter widgets     | Data layer must not know about UI  | Return entities/models; map in presentation      |
| Importing `data/` from `domain/`         | Violates dependency rule           | Domain defines contracts; data implements them   |
| God provider doing everything            | Untestable, hard to maintain       | Split into focused providers per responsibility  |
| Hardcoded strings in UI                  | Breaks localization                | Use ARB-based localization (`context.l10n.key`)  |
| Editing generated files                  | Changes lost on next generation    | Modify source annotations/ARB files instead      |
| Feature folder without layer separation  | Becomes tangled as feature grows   | Use `data/`, `domain/`, `presentation/` subdirs  |
| Circular feature dependencies            | Creates coupling between features  | Extract shared logic to `core/`                  |
| Putting feature-specific code in `core/` | Pollutes shared infrastructure     | Keep in `features/<name>/` until reuse is needed |
| Skipping barrel file updates             | Forces verbose imports everywhere  | Update barrel immediately when adding exports    |

---

## Cross-References

For deeper guidance on specific concerns, consult these companion skills:

- **State management & hooks** → `riverpod-hooks-patterns`
- **UI design system** → `flutter-ui-design-system`
- **App infrastructure** → `flutter-app-infrastructure`
- **Testing patterns** → `flutter-testing-patterns`
