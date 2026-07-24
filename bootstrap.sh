#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter bulunamadı. Flutter 3.44.6+ kurup tekrar çalıştır." >&2
  exit 1
fi
TMP=".platform_bootstrap"
rm -rf "$TMP"
flutter create --platforms=android,ios --org com.kelimefatihi --project-name kelime_fatihi "$TMP"
rm -rf android ios
cp -R "$TMP/android" ./android
cp -R "$TMP/ios" ./ios
rm -rf "$TMP"
flutter pub get
dart run tool/configure_native.dart
dart run flutter_launcher_icons
flutter analyze
flutter test
echo "Hazır. Çalıştır: flutter run"
