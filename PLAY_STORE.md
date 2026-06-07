# SwenBooks Google Play Launch

This repo now includes an Android Trusted Web Activity wrapper for SwenBooks.

## Current Android App Details

- App name: `SwenBooks`
- Package name: `uk.co.swenlink.books`
- Launch URL: `https://books.swenlink.co.uk/app`
- Web origin: `https://books.swenlink.co.uk`
- Android project: `android/`
- Build workflow: `.github/workflows/android-twa.yml`

## Why TWA

The production web app remains the single source of truth. The Android app opens the hosted SwenBooks workspace in a verified, full-screen trusted web activity once Android Digital Asset Links are configured.

## Local Build

Install Android Studio or Android command-line tools, then run:

```bash
gradle -p android :app:bundleDebug
```

The debug bundle is created at:

```text
android/app/build/outputs/bundle/debug/app-debug.aab
```

The GitHub workflow also builds this debug bundle and uploads it as an artifact named `swenbooks-debug-aab`.

## Production Signing

For Play Store production, we need a signed release Android App Bundle.

Recommended approach:

1. Create the app in Google Play Console.
2. Enable Play App Signing.
3. Generate or register an upload key.
4. Configure release signing in CI using GitHub secrets, or build locally from Android Studio.
5. Build:

```bash
gradle -p android :app:bundleRelease
```

Do not commit keystore files or passwords to the repo.

## Digital Asset Links

TWA full-screen verification requires `https://books.swenlink.co.uk/.well-known/assetlinks.json`.

After Play App Signing is enabled, copy the Play app signing SHA-256 certificate fingerprint from:

```text
Play Console -> Test and release -> Setup -> App signing
```

Then replace the placeholder in:

```text
android/assetlinks.template.json
```

Publish the completed JSON file at:

```text
.well-known/assetlinks.json
```

Only add the live `assetlinks.json` after the real SHA-256 fingerprint is known. A placeholder file will not verify the app.

## Play Console Checklist

1. Create app in Play Console.
2. App type: App.
3. Category: Finance or Business.
4. Upload signed `.aab`.
5. Complete App access.
6. Complete Data safety.
7. Complete Content rating.
8. Complete Target audience.
9. Add privacy policy URL.
10. Add store listing text and graphics.
11. Run internal testing.
12. Run closed testing if required by your developer account.
13. Submit production release for review.

## Store Listing Draft

Short description:

```text
Guided accounting for UK limited company directors.
```

Full description:

```text
SwenBooks is an accounting workspace for UK limited company directors and small businesses.

Manage sales invoices, expenses, purchase bills, banking, company dates, director loan movements and reporting in one place. SwenBooks is designed to explain common accounting workflows clearly, including when to record an already-paid purchase as an expense and when to track a supplier invoice as a purchase bill.

Key features:
- Sales invoice tracking
- Expenses and purchase bill workflows
- Smart banking workspace for import, duplicate detection, matching and reconciliation
- Customers and suppliers grouped under People
- Compliance dates, alerts, VAT records and director loan movements
- Light and dark themes
- UK limited company focus

SwenBooks helps with digital record keeping and workflow guidance. It does not replace professional accounting, tax or legal advice.
```

Privacy policy URL:

```text
https://books.swenlink.co.uk/privacy
```

If that URL does not exist before submission, create a privacy policy page first.
