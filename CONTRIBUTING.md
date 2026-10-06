# Contributing to Gainly

Gainly welcomes focused improvements that support its product principles: clarity, consistency, financial awareness, and corrective action.

## Project conventions

- Treat `docs/PRODUCT_SPEC.md` as the functional source of truth.
- Follow the delivery order in `docs/ARCHITECTURE.md`.
- Keep source code, identifiers, comments, tests, filenames, and technical documentation in English.
- Put user-facing translations in the English, French, and Spanish ARB resources.
- Use integer minor units for financial calculations.
- Keep Balance and Performance Balance independent and preserve nullable starting balances.
- Never commit secrets, local environment configuration, real financial fixtures, or privileged Supabase keys.
- Enforce authorization in PostgreSQL RLS, including cross-owner foreign references.

## Verification

Run the relevant checks before submitting a change:

```sh
flutter analyze
flutter test --concurrency=1
npm test --prefix tool/database
```

Keep `docs/IMPLEMENTATION_STATUS.md` aligned with verified behavior and clearly distinguish local checks from live-service or platform acceptance tests.
