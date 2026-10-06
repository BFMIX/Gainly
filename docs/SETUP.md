# Setup

## Prerequisites

- Flutter 3.47.0 and Dart 3.13.0 or a compatible stable release.
- Android SDK / JDK for Android, Xcode for iOS, Chrome for Web.
- A dedicated Supabase project for Gainly. Never reuse an unrelated application's database.
- Node.js for the optional database test harness and Supabase CLI through `npx`.

No paid integration has been introduced. Before provisioning a hosted project, verify the organization's plan, quota, and displayed cost.

## Supabase database

CLI used during initial development: 2.119.0. Discover supported flags with `--help` before operating against a live project.

Apply the ordered files under `supabase/migrations/` using the Supabase migration workflow. The initial migration creates profiles, categories, sources, transactions, owner-only RLS, explicit grants, audit triggers, and the atomic `save_profile` function. The profile-goals migration adds Monthly Target and Daily Minimum constraints and extends the same atomic RPC.

With Docker and Supabase CLI installed, local development can use `supabase start` and `supabase db reset` on a disposable local database. Docker is required for the full local Supabase stack; the PGlite tests do not require it. Never reset a populated remote database.

For a hosted project, link only the confirmed Gainly reference and review the pending migration before pushing it. Re-run the SQL authorization checks and Supabase security advisors after deployment.

## Client configuration

Copy `config/development.example.json` to `config/development.json` and fill in:

- `SUPABASE_URL`: the project's HTTPS API URL.
- `SUPABASE_PUBLISHABLE_KEY`: its publishable client key.

Pass the file with `--dart-define-from-file=config/development.json`. It is intentionally not bundled as an asset. Publishable keys are client configuration, not privileged secrets; authorization comes from RLS. Never put provider client secrets, database passwords, or service-role keys in Flutter configuration.

## Authentication

The following Auth URL settings are required for development:

- Local Web site URL and allowed redirect: `http://localhost:7357`.
- Native allowed redirect: `com.bfmix.gainly://auth-callback`. The app is configured for this value; the hosted dashboard still contains the previous native redirect and must be updated before native Auth acceptance.
- Add the exact production HTTPS URL when a deployment domain is selected.

The app uses PKCE. Native callback handling is configured in AndroidManifest.xml and Info.plist. Flutter's built-in deep-link handling is disabled for these auth callbacks so the Supabase app-links handler owns the exchange.

Enable Google and Apple in Supabase Auth and configure each provider's credentials and callback URL shown in the Supabase dashboard. Provider secrets belong in the provider/Supabase configuration, never in this repository. Apple requires the applicable Apple developer and Sign in with Apple setup. The provisional mobile application identifier is `com.bfmix.gainly`; confirm the final company namespace before the first store submission.

Email fallback uses the default magic-link email template. Configure SMTP and sender settings before public use; default development email delivery is restricted. Sign-in links must open on the same browser/device that initiated the PKCE flow.

Native session persistence uses flutter_secure_storage. iOS Keychain entitlements are included; select the appropriate signing team locally before physical-device distribution. Android backup is disabled for encrypted session storage. Web requires HTTPS or localhost and remains subject to browser/XSS security constraints.

## Hosted acceptance checklist

1. Sign in with each configured provider and email, including native callback return.
2. Complete onboarding with omitted balances, then configure them through Profile.
3. Add included income, excluded income, and an expense. Reload the app and confirm the two balances independently.
4. Sign in with a second account and confirm no first-account data is visible through direct API requests.
5. Sign in on another device and confirm persisted history and profile are restored.
6. Revoke the session and verify protected screens close. Interrupt the network and verify it does not trigger an explicit logout.

Durable offline financial caching and queued offline mutations are not implemented in this first slice and must be completed before offline acceptance is claimed.

## Current development project

The dedicated project is [Gainly in Supabase](https://supabase.com/dashboard/project/tzysspfpovbnmbwvocxh), hosted in Paris. Both current migrations are already applied and the local ignored development configuration is populated. Do not apply them again manually.

The hosted authorization test script is `supabase/tests/ledger_rls.sql`. It creates synthetic users within a transaction, asserts owner isolation and constraints, and rolls back all fixtures. `python3 tool/check_backend.py` checks public Auth reachability and anonymous REST denial without printing keys or sending email.

Official references used: [Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter), [Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth), and [passwordless email](https://supabase.com/docs/guides/auth/auth-email-passwordless).

The provider callback shown by Supabase is `https://tzysspfpovbnmbwvocxh.supabase.co/auth/v1/callback`. Register it with the provider. Google currently requires its Client IDs and OAuth Client Secret; enter credentials directly in the provider/Supabase interfaces, not in chat or repository files.
