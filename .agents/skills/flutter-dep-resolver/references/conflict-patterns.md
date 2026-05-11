# Conflict Patterns Reference

Detailed pub error message patterns mapped to root causes and resolution hints.
Used by the main SKILL.md when error output is ambiguous.

---

## Class A — Direct Constraint Clash

**Typical pub output:**
```
Because myapp depends on pkg_a >=2.0.0 and pkg_b depends on pkg_a <2.0.0,
version solving failed.
```

**Root cause:** Two direct or near-direct dependencies declare incompatible version ranges
for the same shared package.

**Resolution hints:**
- Check if `pkg_a` has a version that satisfies both (e.g., `^1.9.0` might satisfy `<2.0.0` while
  you upgrade your own constraint away from `>=2.0.0`).
- If both `pkg_a` and `pkg_b` are yours to control, align their constraints.
- If `pkg_b` is third-party and outdated, file an issue and use `dependency_overrides` temporarily.

---

## Class B — Transitive Constraint Clash

**Typical pub output:**
```
Because pkg_a >=1.5.0 depends on http >=0.13.0 <1.0.0
  and pkg_b >=3.0.0 depends on http ^1.0.0,
  pkg_a >=1.5.0 is incompatible with pkg_b >=3.0.0.
```

**Root cause:** A package you don't control (`http` here) is pulled in at conflicting versions
by two of your dependencies.

**Resolution hints:**
- The override target is the **shared transitive dep** (`http`), not the packages pulling it.
- Find the version of the transitive dep that satisfies both ranges (or as close as possible).
- Run `flutter pub deps` to see the full tree and confirm you've identified the root.

**Common transitive clash packages in Flutter ecosystems:**
- `http`, `collection`, `meta`, `path`, `crypto`, `typed_data`, `characters`
- `firebase_core` (frequently causes cascading conflicts across firebase_* packages)
- `plugin_platform_interface`

---

## Class C — SDK Constraint Too Narrow

**Typical pub output:**
```
The current Dart SDK version is 3.4.0.
Because pkg_x >=1.0.0 requires SDK version >=2.17.0 <3.0.0,
pkg_x >=1.0.0 is forbidden.
```

**Root cause:** The package's `pubspec.yaml` has a hard SDK upper bound that excludes your
current Dart/Flutter SDK version.

**Resolution hints:**
- Check if there's a newer version of `pkg_x` with a widened SDK constraint on pub.dev.
- If not (unmaintained), fork the package and update the `environment:` block:
  ```yaml
  environment:
    sdk: '>=2.17.0 <4.0.0'
  ```
- In rare cases where forking is too heavy, `dependency_overrides` to an older SDK-compatible
  version works, but you lose any bug fixes from newer versions.

**Flutter SDK variant:**
```
Because pkg_y requires Flutter SDK version >=3.0.0 <3.10.0,
which doesn't match current Flutter 3.22.0...
```
Same approach — fork + widen, or check pub.dev for a patched release.

---

## Class D — Unmaintained Package (No Compatible Release)

**Signals:**
- Last pub.dev publish > 12–18 months ago
- SDK constraint stuck at `<3.0.0` (pre-Dart 3 era)
- GitHub repo archived or no activity
- Null-safety migration not done

**pub output often looks like Class C but the package simply has no newer version.**

**Resolution hierarchy:**
1. **Find an actively maintained fork or replacement** on pub.dev (search for the package name
   with "null safety" or check the package's GitHub issues for migration threads).
2. **Fork and patch** — minimal effort: update `environment:` SDK constraint, run
   `dart pub publish --dry-run` locally to verify.
3. **dependency_overrides** — force a version that your SDK accepts, acknowledging the risk.
4. **Replace the package entirely** — if it's small enough, inline the functionality.

---

## Class E — Flutter Channel / SDK Version Mismatch

**Typical pub output:**
```
The current Flutter SDK version is 3.19.0.
Because flutter_test from sdk depends on collection 1.17.0 and pkg_z >=2.0.0
  depends on collection >=1.18.0...
```

**Root cause:** The Flutter SDK itself ships pinned versions of core packages (`collection`,
`material_color_utilities`, etc.). If a dependency requires a newer version of one of these
pinned packages than your Flutter channel provides, you hit this.

**Resolution hints:**
- Upgrade Flutter channel: `flutter upgrade` or switch to `stable`/`beta` as appropriate.
- If channel upgrade isn't possible, `dependency_overrides` on the pinned package is risky —
  you're overriding a Flutter-internal dep. Proceed carefully and validate heavily with
  `dart analyze` and `flutter test`.
- Check if an older version of `pkg_z` avoids the constraint bump.

---

## Reading `flutter pub deps` Output

```
myapp
├── hooks_riverpod 2.5.1
│   ├── riverpod 2.5.1
│   │   └── state_notifier...
├── dio 5.4.3
│   └── http_parser...
└── legacy_package 0.3.0     ← look for outdated versions here
    └── http 0.12.0           ← and outdated transitives like this
```

**What to look for:**
- Any package with a version significantly behind the current pub.dev release
- Packages whose transitive deps conflict with what other branches of the tree require
- Multiple entries of the same package at different versions (pub will show this with a warning)

---

## Common Package-Specific Conflict Notes

### `firebase_*` ecosystem
Firebase packages are tightly coupled. If you see conflicts inside firebase:
- Update ALL `firebase_*` packages to the same compatible set simultaneously.
- Check the [FlutterFire compatibility matrix](https://github.com/firebase/flutterfire) for
  which versions are tested together.
- `firebase_core` must be upgraded first — it anchors the version of `firebase_core_platform_interface`.

### `hooks_riverpod` / `flutter_riverpod` / `riverpod`
- Never mix `hooks_riverpod` and `flutter_riverpod` — they conflict. Pick one.
- `riverpod` (base package) is a transitive dep; don't declare it directly unless you need
  the plain Dart version specifically.

### `go_router`
- `go_router` has rapid release cycles. Conflicts often arise because other packages
  (e.g., `go_router_builder`) pin an older version. Override or wait for go_router_builder to catch up.

### `dio`
- `dio` >=5.x rewrote its adapter API. If a plugin depends on `dio` <5.0, expect a breaking
  API conflict even if the version constraint resolves. Check the plugin for a `dio5` compatible fork.

### `shared_preferences`
- `shared_preferences` ships platform interface packages (`shared_preferences_android`, etc.)
  that must all be at compatible versions. Upgrading one without the others causes runtime failures
  even when pub resolves cleanly.