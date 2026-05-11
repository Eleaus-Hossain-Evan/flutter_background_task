---
name: flutter-dep-resolver
description: "Expert skill for diagnosing and resolving Flutter/Dart pub dependency conflicts in a single automated run. Use this skill whenever a user reports pub get failures, version constraint errors, SDK incompatibilities, transitive dependency clashes, or any pubspec.yaml conflict. Trigger on phrases like: "dependency conflict", "pub get fails", "version solving failed", "incompatible constraints", "unmaintained package", "dependency_overrides", "pubspec error", or any time the user pastes pub error output. This skill resolves ALL conflicts found in one pass — do not stop after fixing one conflict."
---

# Flutter Dependency Conflict Resolver

A systematic, agentic skill for diagnosing and resolving **all** pub dependency conflicts in
a single run. Read this skill fully before taking any action.

---

## Phase 0 — Orient Before Acting

Before touching any file:

1. **Read `pubspec.yaml`** — understand declared dependencies, existing overrides, and SDK constraints.
2. **Read `pubspec.lock`** if present — reveals what's actually resolved vs. what's declared.
3. **Run diagnosis** to get the full conflict picture:

```bash
flutter pub get 2>&1
flutter pub deps 2>&1
```

4. **Parse all conflicts at once.** Do not fix them one by one iteratively — collect the full
   conflict set first, then apply a coordinated resolution plan.

---

## Phase 1 — Conflict Classification

For each conflict found, classify it using this taxonomy before deciding a fix strategy.
See `references/conflict-patterns.md` for detailed pattern matching.

| Class                                | Signal in Output                                          | Primary Fix                                  |
| ------------------------------------ | --------------------------------------------------------- | -------------------------------------------- |
| **A — Direct constraint clash**      | `Because X depends on pkg >=a and Y depends on pkg <b`    | Widen constraint or override                 |
| **B — Transitive clash**             | A package you don't directly use is conflicting           | `dependency_overrides` on the transitive dep |
| **C — SDK constraint too narrow**    | `Dart SDK >=X.X <Y.Y is forbidden`                        | Fork + widen, or override                    |
| **D — Unmaintained package**         | No recent pub.dev activity; constraint stuck on old range | Git fork or override                         |
| **E — Flutter SDK channel mismatch** | `requires Flutter SDK version`                            | Channel alignment or override                |

---

## Phase 2 — Resolution Strategy Selection

Apply this decision tree **per conflict**, then merge all fixes:

```
Does the conflicting package have a newer pub.dev version that satisfies constraints?
  YES → Upgrade the declared version in pubspec.yaml (cleanest fix)
  NO  →
    Is it a package you directly depend on?
      YES →
        Is the source code accessible / forkable?
          YES → Create a git fork, fix constraint, point pubspec to fork
          NO  → Use dependency_overrides (last resort)
      NO (transitive) →
        Use dependency_overrides targeting only that transitive package
```

**Priority order (cleanest → most forceful):**

1. Version upgrade in `dependencies:` / `dev_dependencies:`
2. Git fork with patched `pubspec.yaml`
3. `dependency_overrides:` on the problematic transitive dep
4. `dependency_overrides:` on a direct dep (only if fork is not viable)

---

## Phase 3 — Applying Fixes

### 3A — Version Upgrade

```yaml
dependencies:
  some_package: ^X.Y.Z # bump to compatible version
```

Always check pub.dev for the latest compatible version before choosing a version number.

### 3B — Git Fork

Use when an unmaintained package only needs a constraint bump:

```yaml
dependencies:
  legacy_package:
    git:
      url: https://github.com/OWNER/legacy_package.git
      ref: main # or a pinned SHA for reproducibility
```

> Prefer a pinned SHA (`ref: abc1234`) over a branch name in production — branches move.

### 3C — dependency_overrides

```yaml
dependency_overrides:
  conflicting_transitive_package: ^X.Y.Z
```

**Rules when using overrides:**

- Target the **lowest common ancestor** dep in the conflict chain, not symptoms.
- Never override a package to a version with breaking API changes from what dependents expect.
- Always add an inline comment explaining WHY and WHEN to remove it:

```yaml
dependency_overrides:
  # TODO: Remove when `legacy_pkg` is migrated (tracked in [issue/ticket]).
  # Overrides conflict between legacy_pkg (needs <2.0) and new_pkg (needs >=2.0).
  conflicting_dep: ^2.1.0
```

### 3D — Handling Multiple Conflicts Simultaneously

Collect ALL fixes into a single pubspec.yaml edit. Apply them together, then run `flutter pub get`
exactly once. If it still fails, go back to Phase 1 with the new error output — do not loop
blindly more than 3 times.

---

## Phase 4 — Verification

After applying all fixes:

```bash
# Must pass cleanly with no warnings
flutter pub get

# Inspect the resolved dependency tree
flutter pub deps

# Run analyzer to catch silent API breakage from overridden versions
dart analyze

# If tests exist, run them
flutter test
```

**What to look for:**

- `flutter pub get` exits with code 0
- No `dependency_overrides` warnings that indicate a risky version jump (e.g., major version bump)
- `dart analyze` shows no new errors (especially in packages affected by overrides)
- If any test fails after resolution, note which override is likely responsible

---

## Phase 5 — Post-Fix Documentation

Always add a summary comment block at the top of the `dependency_overrides:` section
(if one was used), and/or update any existing `# TODO` comments:

```yaml
dependency_overrides:
  # ─── Temporary overrides — review during migration ───────────────────────
  # Added: YYYY-MM-DD
  # Reason: <package> is unmaintained; blocks pub resolve due to <conflict>.
  # Remove when: <package> is replaced with <alternative>.
  # Risk: Low — only affects version resolution, no API surface changed.
  some_dep: ^2.3.0
```

---

## Edge Cases & Gotchas

- **`any` version constraints** — Avoid writing `dependency_overrides: {pkg: any}`. It silences
  all constraint checks and is a footgun. Always specify a real version range.
- **`flutter_test` / SDK packages** — These cannot be overridden. Resolve by aligning Flutter
  SDK version or switching channels.
- **Melos / monorepo setups** — Overrides in the root `pubspec.yaml` of a Melos workspace
  apply to all packages. Be especially careful — check `melos.yaml` for workspace constraints.
- **`pubspec.lock` divergence** — If `pubspec.lock` is committed and conflicts with `pubspec.yaml`
  after your fix, delete `pubspec.lock` and regenerate: `flutter pub get`.
- **Platform plugins with native constraints** — Some plugins (e.g., `camera`, `firebase_*`) have
  native Gradle/CocoaPod constraints that don't show in pub output. If pub resolves cleanly but
  build still fails, check `android/build.gradle` and `ios/Podfile`.

---

## Reference Files

- `references/conflict-patterns.md` — Detailed pub error message patterns and their root causes.
  Read this if the pub output is ambiguous or you're unsure which conflict class applies.

---

## Agent Checklist (run through this before finishing)

- [ ] Ran `flutter pub get` to get full error output first
- [ ] Classified every conflict by type (A–E)
- [ ] Applied the cleanest fix available per conflict (upgrade > fork > override)
- [ ] All overrides have TODO comments with rationale
- [ ] `flutter pub get` exits 0 after all fixes
- [ ] `dart analyze` shows no new errors
- [ ] `pubspec.lock` is consistent (regenerated if needed)
- [ ] Summary of all changes documented in response to user
