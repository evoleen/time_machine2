# system_source_test_app

A minimal Flutter app, used only by CI, that runs the platform-agnostic
`SystemDateTimeZoneSource` checks (`../../test/system_source/checks.dart`) on
Android and iOS devices:

```sh
flutter pub get
flutter test integration_test -d <device> \
  --dart-define=TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE=<the device's zone>
```

See the `Android` and `iOS` jobs in `.github/workflows/sanity.yaml`. It isn't
part of the published package.
