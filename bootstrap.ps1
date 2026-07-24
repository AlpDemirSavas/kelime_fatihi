$ErrorActionPreference = "Stop"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter bulunamadı. Flutter 3.44.6+ kurup tekrar çalıştır."
}
$tmp = ".platform_bootstrap"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
flutter create --platforms=android,ios --org com.kelimefatihi --project-name kelime_fatihi $tmp
if (Test-Path android) { Remove-Item android -Recurse -Force }
if (Test-Path ios) { Remove-Item ios -Recurse -Force }
Copy-Item "$tmp/android" "./android" -Recurse
Copy-Item "$tmp/ios" "./ios" -Recurse
Remove-Item $tmp -Recurse -Force
flutter pub get
dart run tool/configure_native.dart
dart run flutter_launcher_icons
flutter analyze
flutter test
Write-Host "Hazır. Çalıştır: flutter run"
