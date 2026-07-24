import 'package:firebase_core/firebase_core.dart';

/// Bu dosya yalnızca projenin Firebase yapılandırılmadan da derlenebilmesi için
/// yer tutucudur. `flutterfire configure` çalıştırıldığında FlutterFire CLI bu
/// dosyayı gerçek proje değerlerinle otomatik olarak değiştirir.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase henüz yapılandırılmadı. Proje kökünde flutterfire configure çalıştır.',
      );
}
