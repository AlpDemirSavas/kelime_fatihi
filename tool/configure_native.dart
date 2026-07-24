import 'dart:io';

void main() {
  _configureAndroid();
  _configureIos();
  stdout.writeln('Native Android/iOS yapılandırması tamamlandı.');
}

void _configureAndroid() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) return;
  var text = manifest.readAsStringSync();

  if (!text.contains('android.permission.INTERNET')) {
    final manifestStart = text.indexOf('<manifest');
    final endTag = manifestStart < 0 ? -1 : text.indexOf('>', manifestStart);
    if (endTag >= 0) {
      text = '${text.substring(0, endTag + 1)}\n    <uses-permission android:name="android.permission.INTERNET" />${text.substring(endTag + 1)}';
    }
  }

  text = text.replaceAll(
    RegExp(r'android:label="[^"]*"'),
    'android:label="Kelime Fatihi"',
  );

  if (!text.contains('com.google.android.gms.ads.APPLICATION_ID')) {
    text = text.replaceFirst(
      '</application>',
      '        <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="ca-app-pub-3940256099942544~3347511713" />\n    </application>',
    );
  }
  manifest.writeAsStringSync(text);

  final gradleKts = File('android/app/build.gradle.kts');
  if (gradleKts.existsSync()) {
    var gradle = gradleKts.readAsStringSync();
    gradle = gradle.replaceAll('minSdk = flutter.minSdkVersion', 'minSdk = 24');
    gradleKts.writeAsStringSync(gradle);
  }
}

void _configureIos() {
  final info = File('ios/Runner/Info.plist');
  if (!info.existsSync()) return;
  var text = info.readAsStringSync();
  if (!text.contains('GADApplicationIdentifier')) {
    final dictEnd = text.lastIndexOf('</dict>');
    if (dictEnd >= 0) {
      text = '${text.substring(0, dictEnd)}\t<key>GADApplicationIdentifier</key>\n\t<string>ca-app-pub-3940256099942544~1458002511</string>\n${text.substring(dictEnd)}';
    }
  }

  final displayNamePattern = RegExp(
    r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)',
  );
  if (displayNamePattern.hasMatch(text)) {
    text = text.replaceFirstMapped(
      displayNamePattern,
      (match) => '${match.group(1)}Kelime Fatihi${match.group(2)}',
    );
  } else {
    final dictEnd = text.lastIndexOf('</dict>');
    if (dictEnd >= 0) {
      text = '${text.substring(0, dictEnd)}\t<key>CFBundleDisplayName</key>\n\t<string>Kelime Fatihi</string>\n${text.substring(dictEnd)}';
    }
  }

  if (!text.contains('<key>SKAdNetworkItems</key>')) {
    final dictEnd = text.lastIndexOf('</dict>');
    if (dictEnd >= 0) {
      text = '${text.substring(0, dictEnd)}\t<key>SKAdNetworkItems</key>\n\t<array>\n\t\t<dict>\n\t\t\t<key>SKAdNetworkIdentifier</key>\n\t\t\t<string>cstr6suwn9.skadnetwork</string>\n\t\t</dict>\n\t</array>\n${text.substring(dictEnd)}';
    }
  }
  info.writeAsStringSync(text);
}
