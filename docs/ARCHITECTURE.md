# Current architecture

The product specification is the functional source of truth. The current implementation covers the persisted financial flow, category/source management, calendar/history, statistics, and deterministic goal progress. Offline mutation queues and social sharing remain later boundaries.

## Boundaries

- `app`: application lifecycle, theme, and authenticated routing.
- `core/domain`: currency-safe money, profile, transaction, and financial calculations. No Flutter or Supabase dependencies.
- `core/data`: repository contract and Supabase implementation.
- `features`: authentication, onboarding/profile configuration, category/source management, dashboard, transaction entry/history, calendar, statistics, and deterministic goals/progress.
- `localization`: English, French, and Spanish ARB resources with generated Flutter localization code.

Use Flutter state primitives for the first slice instead of a third-party state framework. The repository is injected so tests can substitute an in-memory implementation without exposing a demo login in the production application.

## Financial decisions

Amounts use integer minor units, never floating-point calculations. The initial currency picker supports EUR, USD, and GBP (two decimal places). Broader currency support requires explicit minor-unit metadata. Both starting balances are nullable and independent. An unset starting balance produces an actionable state, not a zero balance. Transactions use a calendar date rather than a timezone-sensitive instant for daily grouping. Audit timestamps use UTC.

Category defaults are copied into each transaction and may be overridden. Changing a category later must not change previous performance results. Soft-deleted transactions do not affect any totals. A quick entry is an additional transaction, not a replacement for the day's existing entries; the form explains this to avoid accidental duplication.

## Persistence and authorization

Supabase is the durable ledger. Every exposed table has owner-only RLS and explicit grants. Composite foreign keys prevent cross-owner category/source references. Onboarding and default categories are saved atomically by a security-invoker RPC. No service-role key is used by the application. The repository pages through the ledger so API row limits cannot silently truncate balances.

OAuth uses Supabase's PKCE flow and native callback links. Email is a magic-link fallback. Native sessions use secure storage. On web the browser storage provided by the secure-storage plugin cannot offer native keychain guarantees; HTTPS and XSS prevention remain essential. Network/auth stream errors do not explicitly sign the user out.

## Delivery sequence

1. Scaffold all platforms, theme, localization, domain and test foundations.
2. Add schema, RLS, atomic onboarding, and repository persistence.
3. Add auth, onboarding/profile, transaction form, dashboard.
4. Add calendar/history, statistics, goals, streaks, and deterministic insights.
5. Run domain/widget tests, analyzer, Web/Android/iOS builds, and database checks.
6. Add restart-safe offline persistence/outbox and conflict handling before claiming offline support.
7. Add server-authorized profile sharing and notifications only after sync hardening.

Do not advertise offline writes before a durable per-user outbox and conflict handling are implemented. Future sync uses timestamped tombstones and Last Write Wins with a documented clock/order strategy; receipt-time timestamps alone are insufficient to compare offline edits.

Form validation is refreshed after a locale change because Flutter caches already-rendered error strings. The regression test covers switching languages after submitting an invalid email form.
