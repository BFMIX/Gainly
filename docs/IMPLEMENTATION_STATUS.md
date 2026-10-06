# Implementation status

Updated: 2026-10-06.

## Implemented scope

- Flutter project for iOS, Android, and Web; local Git repository initialized.
- Feature-oriented structure, Material 3 theme, responsive forms/dashboard, and four-tab navigation shell.
- Generated EN/FR/ES localization, localized validation and financial formatting.
- Supabase OAuth entry points for Google/Apple, email magic links, PKCE callback handling, secure session/verifier storage, and authenticated routing.
- Onboarding with first name, language, currency, and independently optional starting balances.
- Profile configuration; currency changes blocked after any ledger activity.
- Default income/expense categories with copied performance defaults and individual transaction overrides.
- Detailed and quick entry for income/expenses, date, payment method, note, reusable source suggestions, and idempotent transaction IDs.
- Confirmed cloud persistence before balance updates; server-returned audit timestamps.
- Dashboard prioritizing Performance Balance, secondary Balance, daily totals/state, and recent transactions.
- Monthly calendar with direct daily Performance results, state colors, month navigation, and income/expense/result/transaction day details.
- Chronological transaction history with localized search, period/type/category/source/performance filters, existing-entry editing, confirmation, and soft deletion.
- Statistics for selectable periods: balances, totals, daily/weekly/monthly results, category/source distributions, day-state counts, Positive Day Rate, longest positive streak, and Performance Balance evolution.
- Optional Monthly Target and user-controlled Daily Minimum persisted in the profile, with dynamic calendar-day pace, Tracking/Positive streaks, and at most two deterministic Smart Insights.
- Integer minor-unit financial calculations and distinct no-activity/zero-after-activity states.
- Owner-only schema/RLS, cross-owner foreign-key protection, soft-deletion fields, audit guards, explicit API grants, and atomic onboarding RPC.

## Hosted backend

A dedicated **Gainly** project exists in **BFMIX ORG**, region **eu-west-3 (Paris)**, reference `tzysspfpovbnmbwvocxh`. The connector quoted $0/month at creation. This is the observed project quote, not a guarantee for future usage or plan changes.

Both migrations have been applied and their local versions match hosted history: `20261005060828` for the initial ledger and `20261005210125` for profile goals. The ignored `config/development.json` connects the app using the project's publishable key. No service-role key is used.

Hosted RLS tests passed with two synthetic accounts inside a rolled-back transaction. No test users or ledger entries were retained. After the goals migration, the security advisor reported only that leaked-password protection is disabled; Gainly currently exposes OAuth and passwordless email rather than password sign-in. Reassess this setting before adding passwords. Performance advice listed two currently unused transaction indexes on the new empty ledger; these support owner/date and category access and are intentionally retained. See [Supabase's unused-index advisory](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index).

Read-only API checks confirmed the Auth endpoint is reachable and anonymous REST access to profiles, categories, sources, and transactions is denied (401). Current provider settings: email and Google enabled; Apple disabled.

Auth Site URL remains `http://localhost:7357` for local fallback. The hosted redirect allowlist contains local Web, `https://bfmix.github.io/Gainly/`, and `com.bfmix.gainly://auth-callback`; the previous native redirect has been removed.

## Verification evidence

- The public GitHub Pages workflow completed successfully and `https://bfmix.github.io/Gainly/` returned HTTP 200 with the expected `/Gainly/` Flutter base path.
- Google OAuth initiation from the public Pages release reached Google's account chooser with the Supabase callback and the exact Pages `redirect_to` value. Account selection and consent remain a user-controlled acceptance step.
- Final Web release, Android debug APK, and iOS simulator builds succeeded with the actual Gainly development configuration.
- Final `flutter analyze` reported no issues.
- 43 unit/widget tests passed: financial calculations, nullable baselines, included/excluded transactions, daily states, tombstones, failed writes/refreshes, idempotence, concurrent refresh handling, EN/FR/ES rendering, validation-message language changes, onboarding-to-dashboard flow, calendar/history behavior, statistics, persisted goal settings, dynamic pace, streaks, Positive Day Rate, deterministic insights, and GitHub Pages authentication redirect preservation.
- 25 PGlite/PostgreSQL checks passed for both migrations, goal constraints, RLS, invalid/cross-owner references, currency guard, soft deletion, and anonymous access.
- Hosted SQL/RLS suite passed; anonymous REST checks passed.
- iOS simulator secure session and PKCE storage round-trip passed, including restoration through a new storage instance and deletion.
- iOS simulator financial-flow integration passed: onboarding, transaction entry, repository persistence, and independent balance display. Both native integration tests passed.

The UI tests inject an in-memory repository; they do not prove hosted OAuth or a real authenticated PostgREST round trip. The hosted SQL tests validate database behavior separately. Do not label the full hosted user journey accepted until the configured-auth acceptance checklist passes.

## Remaining setup

- Complete a real Google account selection, consent, callback, and persisted-session acceptance test. Enable Apple later with its provider credentials.
- Confirm email delivery/SMTP and perform a real email magic-link round trip.
- Verify sign-in, persisted ledger reload, revocation, and cross-device recovery with a real authorized test account.
- Confirm or replace the provisional `com.bfmix.gainly` identifier, then select the signing team and distribution configuration before the first store submission.

The authenticated Supabase dashboard was used to configure and verify the callback URLs. Google is enabled with its provider credentials; Apple remains disabled pending its provider credentials. The CLI remains unauthenticated. No credential substitution or demo auth bypass is present.

## Subsequent MVP work

Category/source management; basic badges; durable local financial cache and queued offline mutations; Last Write Wins/conflict tests; invitations and independent server-enforced sharing; notification preferences.

The current slice retains loaded data after a refresh error and persists authentication. It does **not** yet provide restart-safe offline financial data, offline writes, sync queues, or cross-device conflict resolution. Sync tests will be introduced with that implementation, not as misleading placeholders.

The connected Web release was inspected in the in-app browser: the French sign-in screen rendered, email validation ran locally without sending a message, and the language selector switched the interface to Spanish. Hosted provider sign-in itself remains unverified.
