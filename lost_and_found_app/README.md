# lost_and_found_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase setup

The app uses Firebase Authentication (email/password) and Cloud Firestore.
For local development without a Firebase account or project, install Node.js
and Java, then run these commands in the app folder:

```powershell
npx --yes firebase-tools@15.37.0 emulators:start --only auth,firestore --project demo-campus-lost-and-found
```

In another terminal:

```powershell
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

Open the Emulator UI at `http://127.0.0.1:4000`. Create an account in the app,
then use the Firestore tab to change its `users/{uid}` profile role to `staff`
or `admin` for testing. Emulator data is local and is not production data.

For production, create a Firebase project, enable email/password sign-in,
create a Firestore database, and configure a supported app with FlutterFire.
The generated platform app IDs are supplied as Dart defines; Firebase API keys
and app IDs are public client configuration, not authorization secrets.

Required defines:

- Shared: `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`,
  `FIREBASE_MESSAGING_SENDER_ID`
- Web: `FIREBASE_WEB_APP_ID`, `FIREBASE_AUTH_DOMAIN`
- Android: `FIREBASE_ANDROID_APP_ID`
- iOS: `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID`
- macOS: `FIREBASE_MACOS_APP_ID`, `FIREBASE_MACOS_BUNDLE_ID`

For example, run the web app with:

```powershell
flutter run -d chrome --dart-define=FIREBASE_API_KEY=<api-key> --dart-define=FIREBASE_PROJECT_ID=<project-id> --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> --dart-define=FIREBASE_WEB_APP_ID=<web-app-id> --dart-define=FIREBASE_AUTH_DOMAIN=<project-id>.firebaseapp.com
```

Configure Firestore rules with `firebase deploy --only firestore:rules` from
this directory. `firestore.rules` ensures public registration creates only
student profiles, users cannot alter their own role, and only staff/admins can
read or review reports and claims. Admins can manage user roles.

To establish the first admin, register the account normally, then edit its
`users/{uid}` profile in Firestore from the Firebase console and set
`role: "admin"`. The console is a trusted administrative channel and bypasses
client rules. After that, admins can promote other accounts in the app.

## User roles

New accounts are always registered as students. Staff and admins can review
reports and claims; only admins can manage user roles. Unauthorized page access
shows **Access denied**. UI checks improve usability, while Firestore rules
enforce permissions on the backend.

Firebase Auth and Firestore plugins currently support the web, Android, iOS,
and macOS targets configured by this scaffold. Windows and Linux desktop
targets display an explicit unsupported-platform setup message.
