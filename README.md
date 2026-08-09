# Fixit GH

A Flutter service marketplace app connecting customers with artisans across Ghana. Built with Flutter, Provider, and Supabase.

## Live demo

After GitHub Pages is enabled, the app is hosted at:

- App: `https://edoboyy.github.io/fixit_it/`
- Phone-frame demo page: `https://edoboyy.github.io/fixit_it/demo/`

## Portfolio embed

To show the app inside a phone frame on your portfolio site, copy the HTML/CSS block from:

- `portfolio/embed-snippet.html`

That snippet loads the hosted app in an iframe inside a mobile-style frame.

## Deploy to GitHub Pages

1. Push to the `main` branch.
2. In GitHub, open **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to **GitHub Actions**.
4. Wait for the `Deploy Flutter Web to GitHub Pages` workflow to finish.

## Supabase setup for the live demo

In your Supabase project, add these URLs:

- **Authentication → URL configuration → Site URL:** `https://edoboyy.github.io/fixit_it/`
- **Redirect URLs:** `https://edoboyy.github.io/fixit_it/**`

Also run the SQL files in the Supabase SQL Editor:

- `supabase/schema.sql`
- `supabase/fix_rls.sql`

## Local development

```bash
flutter pub get
flutter run -d chrome
```

For Windows desktop builds with plugins, enable **Developer Mode** in Windows settings first.
