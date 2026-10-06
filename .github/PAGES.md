# GitHub Pages deployment

The `deploy-pages.yml` workflow verifies and publishes the Flutter Web release
for the `main` branch at `https://bfmix.github.io/Gainly/`.

Before the first deployment:

1. In **Settings → Secrets and variables → Actions**, add repository secrets
   named `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Use the public project
   URL and publishable key; never use a service-role key.
2. In **Settings → Pages**, select **GitHub Actions** as the Pages source.
3. In Supabase Auth URL configuration, allow
   `https://bfmix.github.io/Gainly/` as a redirect URL before testing email or
   social sign-in from the deployed application.

The workflow passes the two values directly to `flutter build web` through
environment-backed Dart defines. It does not create or upload a local config
file.
