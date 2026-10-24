# TakeOne

TakeOne is an offline-first digital clapboard for Android, built with Flutter.
Projects, slate setup, and take history are stored locally in SQLite; appearance
preferences are stored on the device.

## Features

- Create and manage production projects with director, DOP, date, location, and notes.
- Configure roll, scene, shot, take, frame rate, slate field labels, order, visibility,
  and text size for each project.
- Use the full-screen landscape slate to clap, capture timecode, and rate takes.
- Advance takes, move to the next shot or scene, and record test takes without
  changing the normal take counter.
- Review, filter, edit, and delete take history.
- Export project details and take logs to a shareable PDF.
- Choose cinematic, dark, or light themes, accent colors, and typefaces.

## Run

```sh
flutter pub get
flutter run
```

Build a debug APK with:

```sh
flutter build apk --debug
```

Run the Android workflow test on a connected device with:

```sh
flutter test integration_test/app_test.dart -d <device-id>
```
