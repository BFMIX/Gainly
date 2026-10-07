# Current architecture

The product specification is the functional source of truth. The current implementation covers the persisted financial flow, category/source management, calendar/history, statistics, deterministic goal progress and achievements, restart-safe offline synchronization, and local notifications. Social sharing remains a later boundary.

## Boundaries

- `app`: application lifecycle, theme, and authenticated routing.
- `core/domain`: currency-safe money, profile, transaction, and financial calculations. No Flutter or Supabase dependencies.
- `core/data`: repository contract, Supabase implementation, encrypted local cache, and durable mutation queue.
- `features`: authentication, onboarding/profile configuration, category/source management, dashboard, transaction entry/history, calendar, statistics, deterministic goals/progress and achievements, and notification planning/delivery.
- `localization`: English, French, and Spanish ARB resources with generated Flutter localization code.

Use Flutter state primitives for the first slice instead of a third-party state framework. The repository is injected so tests can substitute an in-memory implementation without exposing a demo login in the production application.

## Financial decisions

Amounts use integer minor units, never floating-point calculations. The initial currency picker supports EUR, USD, and GBP (two decimal places). Broader currency support requires explicit minor-unit metadata. Both starting balances are nullable and independent. An unset starting balance produces an actionable state, not a zero balance. Transactions use a calendar date rather than a timezone-sensitive instant for daily grouping. Audit timestamps use UTC.

Category defaults are copied into each transaction and may be overridden. Changing a category later must not change previous performance results. Soft-deleted transactions do not affect any totals. A quick entry is an additional transaction, not a replacement for the day's existing entries; the form explains this to avoid accidental duplication.

## Persistence and authorization

Supabase is the durable ledger. Every exposed table has owner-only RLS and explicit grants. Composite foreign keys prevent cross-owner category/source references. Onboarding and default categories are saved atomically by a security-invoker RPC. No service-role key is used by the application. The repository pages through the ledger so API row limits cannot silently truncate balances.

The application keeps a per-account Hive cache and mutation queue. Native cache files are encrypted with a random 256-bit key stored through secure platform storage. Web storage uses the browser storage available to the secure-storage and Hive plugins; it cannot provide native keychain isolation. Cache initialization failure leaves online operation available without claiming offline support for that run.

Profile, category, source, and transaction mutations are applied locally first. Synchronization replays them in dependency order and persists progress after each accepted mutation. Connectivity changes trigger a retry, but connectivity status is only a hint; every request still handles network failure. Transaction edits use client UTC `updated_at` values for Last Write Wins. The server locks the row, keeps the newer timestamp, treats equal timestamps as idempotent, and records receipt time in `synced_at`. Device clock skew can affect conflict ordering; a future hybrid logical clock may replace this MVP strategy.

OAuth uses Supabase's PKCE flow and native callback links. Email is a magic-link fallback. Native sessions use secure storage. On web the browser storage provided by the secure-storage plugin cannot offer native keychain guarantees; HTTPS and XSS prevention remain essential. Network/auth stream errors do not explicitly sign the user out.

## Notifications

Notification preferences are owner-scoped in Supabase and use the same durable offline queue as profile settings. Important alerts and the 20:00 local daily reminder are enabled by default; streak, achievement, goal-progress, and positive-milestone messages require opt-in. Performance Balance risk covers crossing zero, crossing down to 10 currency units or less, and a drop of at least 25% and 50 currency units. Negative-day warnings require three adjacent calendar days. The planning engine emits at most one financial alert for each ledger mutation, with Performance Balance risk taking priority.

iOS and Android request notification authorization when an enabled account first loads, schedule the next daily reminder in local time, and restore it after reboot on Android. Signing out cancels the account reminder. The app uses inexact Android scheduling, so it does not request exact-alarm access. Web browsers support immediate notifications while the app is open, but the notification plugin cannot schedule delivery after the page is closed; the settings screen explains this limitation.

## Delivery sequence

1. Scaffold all platforms, theme, localization, domain and test foundations.
2. Add schema, RLS, atomic onboarding, and repository persistence.
3. Add auth, onboarding/profile, transaction form, dashboard.
4. Add calendar/history, statistics, goals, streaks, and deterministic insights.
5. Run domain/widget tests, analyzer, Web/Android/iOS builds, and database checks.
6. Add restart-safe offline persistence/outbox and Last Write Wins conflict handling.
7. Add configurable local notifications after sync hardening.
8. Add server-authorized profile sharing.

Offline writes use timestamped tombstones and a durable per-user outbox. Server receipt timestamps remain separate from the client modification timestamps used for conflict ordering.

Form validation is refreshed after a locale change because Flutter caches already-rendered error strings. The regression test covers switching languages after submitting an invalid email form.
