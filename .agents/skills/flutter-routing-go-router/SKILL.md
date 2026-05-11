---
name: flutter-routing-go-router
description: "Canonical router guidance for Appeler using go_router + Riverpod. Covers router ownership, redirect state machine, auth back-intent replay, deep-link canonicalization, Firebase/REST session interactions, test matrix, and anti-patterns. Explicitly treats app_links lifecycle orchestration as non-canonical for this repository."
---

# Router-Native Routing (go_router + Riverpod)

You are the routing expert for Appeler. Keep navigation decisions centralized in the router layer, driven by session state, and deterministic across mobile/web.

---

## 1 - Canonical Ownership

### Source of truth

- Route ownership lives in `lib/core/router/router.dart` (`appRouterProvider`).
- Path and query contracts live in `lib/core/router/route_paths.dart`.
- URI normalization and safe replay helpers live in `lib/core/router/route_utils.dart`.
- App bootstrap consumes the router via `MaterialApp.router` and `routerConfig: ref.watch(appRouterProvider)`.

### Canonical pattern for this repo

- Use **go_router-native URI parsing + redirect** for deep-link handling.
- Use **Riverpod session providers + refreshListenable** to trigger redirect reevaluation.
- Keep redirect logic **pure and side-effect free**.

### Explicit non-canonical pattern

- `app_links` lifecycle orchestration (`getInitialLink`, foreground `uriLinkStream`, imperative navigation from lifecycle callbacks) is **not** the canonical routing pattern in this repository.
- If legacy `app_links` code exists in older branches/history, treat it as migration compatibility only, not target architecture.

---

## 2 - Redirect State Machine

Apply redirects in this order:

1. Canonicalize incoming URI first.
2. Read current auth/session state.
3. Apply deterministic redirect rules.
4. Preserve unknown paths for router error rendering.

### Recommended shape

```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);

  ref
    ..onDispose(refresh.dispose)
    ..listen<AuthSessionState>(
      authSessionStateProvider,
      (_, __) => refresh.value++,
    );

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final incoming = RouteUtils.stateLocation(state);
      final canonical = RouteUtils.canonicalStateLocation(state);
      if (incoming != canonical) {
        return canonical;
      }

      final session = ref.read(authSessionStateProvider);
      return redirectForSessionState(session: session, location: canonical);
    },
    // routes...
  );
}
```

> For stream-first auth sources, `GoRouterRefreshStream(authStream)` is an equivalent trigger pattern. Keep the same pure redirect contract.

### State transitions

| Session state     | Allowed directly         | Redirect behavior                                       |
| ----------------- | ------------------------ | ------------------------------------------------------- |
| `Loading`         | launcher/splash          | Redirect everything else to launcher (or splash gate)   |
| `Unauthenticated` | public/auth entry routes | Protected routes -> auth entry/welcome with back intent |
| `Authenticated`   | shell/protected routes   | Auth entry routes -> replay back intent or home         |
| Unknown path      | none                     | Do not force rewrite; let `errorBuilder` render safely  |

---

## 3 - Auth + Back-Intent Replay

When an unauthenticated user hits a protected deep link:

1. Sanitize target into internal location format.
2. Attach as `back` query parameter on public entry route.
3. After successful auth, replay only if target is still valid.
4. Fallback to default authenticated destination (`/home`) when replay target is absent/invalid.

### Rules

- Accept only internal, relative paths beginning with `/`.
- Reject external URLs/schemes/authorities.
- Strip nested `back` to avoid replay loops.
- Replay only to protected destinations allowed by current route policy.

---

## 4 - Deep-Link Canonicalization

Canonicalize every incoming location before redirect decisions:

- Normalize whitespace, leading slash, trailing slash.
- Drop fragments (`#...`).
- Trim empty query keys/values.
- Map legacy aliases to canonical paths (example: `/app/*` -> `/home/*`).
- Canonicalize auth aliases (example: `/auth`, `/auth/signup`, `/auth/sign-up` -> canonical auth routes).
- Apply route family fallback for constrained link types (for example, `meeting_id` links to shell-safe meeting routes).

### Unknown route handling

- Keep unknown paths untouched so the router error surface can display attempted location and fail safely.

### Firebase Dynamic Links context (historical/deprecated)

- Firebase Dynamic Links is deprecated and the service shut down on **August 25, 2025**.
- Treat Dynamic Links SDK callback flows as historical migration context only.
- Canonical deep-link handling for this repo is go_router-native route parsing/canonicalization from platform app/universal links.

---

## 5 - Firebase + REST Session Impacts

The router should depend on a **unified session state provider**, not on Firebase or REST calls directly.

### Contract

- `AuthSessionLoading`
- `AuthSessionAuthenticated`
- `AuthSessionUnauthenticated`

### Integration guidance

- Feed state from Firebase auth stream and any REST token refresh/validation layer into one provider contract.
- On app resume/startup token refresh, emit `Loading` and let router gate navigation consistently.
- On REST `401` or session revocation, transition to unauthenticated state; router handles redirect.
- On successful refresh/sign-in, transition to authenticated; router reevaluates and replays back intent if present.

### Guardrails

- Never make HTTP calls inside `GoRouter.redirect`.
- Never mutate auth/session state from inside redirect.
- Keep redirects synchronous (or minimal `FutureOr`) and deterministic.

---

## 6 - Testing Matrix

Minimum routing test coverage:

| Scenario                                  | Setup                                            | Expected outcome                                      |
| ----------------------------------------- | ------------------------------------------------ | ----------------------------------------------------- |
| Legacy alias canonicalization             | Authenticated + legacy path deep link            | Canonical path location                               |
| Protected deep link while unauthenticated | Unauthenticated + protected URI                  | Public entry route with encoded back intent           |
| Auth entry while authenticated            | Authenticated + sign-in/sign-up route            | Redirect to home                                      |
| Back replay after auth                    | Authenticated + auth route with back query       | Redirect to sanitized protected target                |
| Unknown route safety                      | Unknown URI                                      | Router error screen, location preserved               |
| Loading gate                              | Session in loading                               | Non-bootstrap locations redirected to launcher/splash |
| Session transition refresh                | Session changes unauthenticated -> authenticated | Redirect reevaluated without manual navigation calls  |
| REST expiry path                          | Simulate token invalidation                      | Router transitions to unauthenticated entry path      |

### Test harness pattern

- Build router from `ProviderContainer` overrides.
- Pump via shared helper (`ProviderScope` + `MaterialApp.router`).
- Assert final `router.routeInformationProvider.value.uri` location.

---

## 7 - Anti-Patterns (Do Not Introduce)

- Lifecycle-driven deep-link orchestration with `app_links` as routing authority.
- Imperative `context.go/push` calls from app lifecycle listeners to emulate routing state machine.
- `Navigator.push` usage for app navigation outside go_router contracts.
- Hardcoded route strings at call sites when route constants/utilities exist.
- Async network logic in redirect callbacks.
- Unsanitized `back` query replay (open redirect risk).
- Multiple competing router owners.

---

## 8 - Implementation Checklist

1. Add/update route constants in `RoutePaths`.
2. Register route tree changes in `appRouterProvider`.
3. Update canonicalization rules in `RouteUtils` for any new legacy alias/shape.
4. Validate redirect state machine branches for loading/auth/unauth states.
5. Add or update tests from the matrix above.
6. Confirm no new lifecycle deep-link orchestration was introduced.
