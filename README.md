# Business Card

Business Card is a Flutter app for capturing business card images, reviewing extracted contact details, adding a remark, and saving the result to Firestore. Images are uploaded through a Google Apps Script web app, and saved cards are scoped to the signed-in Firebase user.

## What the app does

- Signs users in with Firebase Authentication.
- Accepts either a full email address or a username.
- Maps username logins to `<username>@<domain>` for Firebase email/password auth.
- Lets the user scan a card from the camera or pick one from the gallery.
- Builds a draft card with extracted contact fields and a free-form remark.
- Uploads the selected image to Google Drive through Apps Script.
- Saves card metadata in Firestore.
- Shows a searchable, sortable list of saved cards.

## Current behavior and limitations

- The extraction layer is currently a placeholder.
  - `TextRecognitionService` does not run real OCR yet.
  - It derives the contact name from the image filename and fills the other fields with mock values.
- Saved-card search currently filters only by `remark`.
- Firebase is configured in this repo for Android and iOS.
  - Web, macOS, Windows, and Linux are scaffolded in Flutter, but Firebase options are not configured for them in `lib/firebase_options.dart`.
- The upload flow depends on a deployed Google Apps Script endpoint that accepts base64 image data and returns a URL or file path.

## Tech stack

- Flutter
- Riverpod
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Storage dependency is present, but the current image upload flow uses Google Apps Script + Google Drive
- `image_picker`
- `http`

## Project structure

```text
lib/
  app/
    app.dart                  # App shell and auth gate
    theme.dart                # Material 3 theme
  core/
    app_config.dart           # dart-define backed runtime config
    firebase_bootstrap.dart   # Firebase initialization guard
    widgets/status_banner.dart
  features/
    auth/
      application/
      data/
      domain/
      presentation/
    cards/
      application/
      data/
      domain/
      presentation/
  services/
    google_drive_upload_service.dart
    image_picker_service.dart
    text_recognition_service.dart
  main.dart
```

## App flow

1. The app boots Firebase in `main.dart`.
2. `BusinessCardApp` decides between `LoginPage` and `HomePage` based on auth state.
3. The user signs in with either:
   - a real email address, or
   - a username, which is mapped to `<username>@<AUTH_EMAIL_DOMAIN>`.
4. On scan, the app opens camera or gallery with `image_picker`.
5. `TextRecognitionService` creates a draft contact from the selected image.
6. The user reviews the draft, adds a remark, and saves it.
7. `GoogleDriveUploadService` posts the image to the configured Apps Script URL.
8. `BusinessCardRepository` stores the saved card in Firestore under the configured collection.
9. The Saved tab loads cards for the current Firebase user only.

## Configuration

Runtime configuration lives in [`lib/core/app_config.dart`](/Users/achu/StudioProjects/BusinessCard/lib/core/app_config.dart:1).

Supported `--dart-define` values:

| Key | Default | Purpose |
| --- | --- | --- |
| `GOOGLE_APPS_SCRIPT_URL` | hardcoded fallback URL in `AppConfig` | Endpoint used to upload images to Google Drive |
| `FIRESTORE_CARDS_COLLECTION` | `scanned_cards` | Firestore collection used for card records |
| `AUTH_EMAIL_DOMAIN` | `businesscard.local` | Domain used when a user signs in with a plain username |

Example:

```bash
flutter run \
  --dart-define=GOOGLE_APPS_SCRIPT_URL=https://script.google.com/macros/s/your-script-id/exec \
  --dart-define=FIRESTORE_CARDS_COLLECTION=scanned_cards \
  --dart-define=AUTH_EMAIL_DOMAIN=yourcompany.com
```

## Firebase setup

This repository already contains:

- `android/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- generated FlutterFire options in [`lib/firebase_options.dart`](/Users/achu/StudioProjects/BusinessCard/lib/firebase_options.dart:1)

To use a different Firebase project:

1. Create or select a Firebase project.
2. Enable Email/Password authentication.
3. Create a Firestore database.
4. Replace the Android and iOS Firebase config files.
5. Regenerate `lib/firebase_options.dart` if needed.

Important auth detail:

- If a user signs in with `alex`, the app attempts Firebase auth with `alex@businesscard.local` by default.
- If sign-in fails for a username-based account, the repository may auto-create that Firebase user for first-time usage.
- If your Firebase users should map to a real company domain, set `AUTH_EMAIL_DOMAIN`.

## Google Drive upload contract

The upload service expects the Apps Script web app to:

- accept a POST request
- read these form fields:
  - `fileName`
  - `name`
  - `mimeType`
  - `data` as base64
- return either:
  - JSON containing one of `image_path`, `filePath`, `path`, `url`, `fileUrl`, or `webViewLink`, or
  - a plain-text URL

If the script returns `success: false`, the app surfaces the provided message as an error.

## Firestore document shape

Cards are saved with fields matching `SavedBusinessCard.toFirestoreMap()` in [`lib/features/cards/domain/saved_business_card.dart`](/Users/achu/StudioProjects/BusinessCard/lib/features/cards/domain/saved_business_card.dart:1):

```json
{
  "image_path": "https://...",
  "created_date": "server timestamp",
  "remarks": "Met at expo",
  "description": "Name: ...\nCompany: ...\nPhone: ...\nEmail: ...",
  "name": "Contact Name",
  "company": "Company Name",
  "phone": "+91 90000 00000",
  "email": "contact@example.com",
  "owner_uid": "firebase-user-id",
  "created_by": "username"
}
```

## Getting started

```bash
flutter pub get
flutter run
```

If you need custom runtime values, use the `--dart-define` example above.

## Main files

- [`lib/main.dart`](/Users/achu/StudioProjects/BusinessCard/lib/main.dart:1): bootstraps Firebase and Riverpod
- [`lib/app/app.dart`](/Users/achu/StudioProjects/BusinessCard/lib/app/app.dart:1): routes between login and home
- [`lib/features/auth/data/auth_repository.dart`](/Users/achu/StudioProjects/BusinessCard/lib/features/auth/data/auth_repository.dart:1): Firebase sign-in logic and username-to-email mapping
- [`lib/features/cards/application/card_scan_controller.dart`](/Users/achu/StudioProjects/BusinessCard/lib/features/cards/application/card_scan_controller.dart:1): main state management for scanning and saved cards
- [`lib/features/cards/data/business_card_repository.dart`](/Users/achu/StudioProjects/BusinessCard/lib/features/cards/data/business_card_repository.dart:1): Firestore persistence and upload orchestration
- [`lib/services/google_drive_upload_service.dart`](/Users/achu/StudioProjects/BusinessCard/lib/services/google_drive_upload_service.dart:1): Apps Script upload client
- [`lib/services/text_recognition_service.dart`](/Users/achu/StudioProjects/BusinessCard/lib/services/text_recognition_service.dart:1): placeholder extraction service

## Next improvements

- Replace placeholder extraction with a real OCR pipeline.
- Move image storage to Firebase Storage if you want a Firebase-only backend.
- Add Firestore security rules documentation.
- Extend search to include name, company, phone, and email.
- Persist auth session into app state on startup instead of relying only on the in-memory controller state.
