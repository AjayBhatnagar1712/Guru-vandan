# Guruvandan

Guruvandan is a Flutter app for a spiritual school where devotees can follow a simple daily practice routine.

## Features

- Morning and evening satsang audio
- Meditation timer with chant sound on completion
- Daily Sadguru Maharaj quotes
- Local streak tracking for routine consistency
- Firebase-ready admin console for uploading satsang audio and adding quotes

## Tech Stack

- Flutter and Dart for Android, iOS, and web
- Firebase Auth for admin login
- Firebase Realtime Database for satsang metadata and quotes
- Firebase Storage for uploaded satsang audio
- `audioplayers` for satsang and meditation audio
- `shared_preferences` for local streak tracking

## Local Preview

Flutter is installed on this machine at:

```text
C:\src\flutter\flutter_windows_3.38.6-stable\flutter\bin\flutter.bat
```

Run the app locally:

```powershell
cd "D:\DCAM\Guruvandan app\guruvandan_flutter"
& "C:\src\flutter\flutter_windows_3.38.6-stable\flutter\bin\flutter.bat" pub get
& "C:\src\flutter\flutter_windows_3.38.6-stable\flutter\bin\flutter.bat" run -d chrome
```

Build web:

```powershell
& "C:\src\flutter\flutter_windows_3.38.6-stable\flutter\bin\flutter.bat" build web
```

## Live Web App

This repo includes a GitHub Actions workflow that builds Flutter Web and deploys it to GitHub Pages.

Expected public URL after GitHub Pages is enabled:

```text
https://ajaybhatnagar1712.github.io/Guru-vandan/
```

## Firebase

The project currently uses Firebase project values discovered from the Android repo:

- project id: `guru-vandan`
- realtime database: `https://guru-vandan-default-rtdb.asia-southeast1.firebasedatabase.app/`
- storage bucket: `guru-vandan.firebasestorage.app`

Before production, create proper Firebase web and iOS apps in the same Firebase project and replace placeholder values in `lib/main.dart`.

## Admin Console

Open the app and go to:

```text
More -> Open admin console
```

Allowed admin email is currently:

```text
ajaybhatnagar1712@gmail.com
```
