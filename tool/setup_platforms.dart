// One-time setup: generates the android/ and ios/ folders and adds the
// permissions Agora video calls need.
//
//   cd app
//   dart run tool/setup_platforms.dart
//
// Safe to run again — every patch checks whether it is already applied.

import 'dart:io';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the app/ folder (where pubspec.yaml is).');
    exit(1);
  }

  // 1. Generate platform folders (keeps lib/, pubspec.yaml and test/ untouched).
  await _run('flutter', [
    'create',
    '--org',
    'com.medconnect',
    '--project-name',
    'medconnect',
    '--platforms=android,ios',
    '.',
  ]);
  await _run('flutter', ['pub', 'get']);

  // `flutter create` adds a counter-app widget test that doesn't apply to this app.
  final templateTest = File('test/widget_test.dart');
  if (templateTest.existsSync() && templateTest.readAsStringSync().contains('MyApp')) {
    templateTest.deleteSync();
  }

  _patchAndroidManifest();
  _writeProguardRules();
  _patchGradleCompileSdk();
  _patchInfoPlist();

  // The iOS Podfile is created by the first iOS build. Generate it now on a Mac.
  if (Platform.isMacOS && !File('ios/Podfile').existsSync()) {
    await _run('flutter', ['build', 'ios', '--config-only', '--no-codesign'], allowFail: true);
  }
  _patchPodfile();

  stdout.writeln('''

✅ Platform setup done.

Next:
  flutter run   (on first launch, enter your medconnect-web address, e.g. https://medconnect-web.vercel.app)
''');
}

Future<void> _run(String cmd, List<String> args, {bool allowFail = false}) async {
  stdout.writeln('\$ $cmd ${args.join(' ')}');
  final p = await Process.start(cmd, args, mode: ProcessStartMode.inheritStdio, runInShell: true);
  final code = await p.exitCode;
  if (code != 0 && !allowFail) {
    stderr.writeln('Command failed ($code): $cmd ${args.join(' ')}');
    exit(code);
  }
}

void _patchAndroidManifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) {
    stderr.writeln('⚠  $f not found — skipping Android permissions.');
    return;
  }
  var xml = f.readAsStringSync();
  const permissions = [
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.MODIFY_AUDIO_SETTINGS',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.ACCESS_WIFI_STATE',
    'android.permission.BLUETOOTH_CONNECT',
    'android.permission.WAKE_LOCK',
  ];
  final missing = permissions.where((p) => !xml.contains('"$p"')).toList();
  if (missing.isNotEmpty) {
    final lines = missing.map((p) => '    <uses-permission android:name="$p" />').join('\n');
    xml = xml.replaceFirst('<application', '$lines\n    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />\n\n    <application');
  }
  // Allows http:// to your local backend while testing. Remove for production (use https).
  if (!xml.contains('usesCleartextTraffic')) {
    xml = xml.replaceFirst('<application', '<application\n        android:usesCleartextTraffic="true"');
  }
  f.writeAsStringSync(xml);
  stdout.writeln('✓ Android permissions added');
}

/// agora_rtc_engine compiles against an old Android SDK; force all library plugins to SDK 36.
void _patchGradleCompileSdk() {
  final f = File('android/build.gradle.kts');
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  if (s.contains('forceCompileSdk')) return;
  const anchor = 'subprojects {\n    project.evaluationDependsOn(":app")';
  const block = """// Some plugins (e.g. agora_rtc_engine) still compile against an old Android SDK.
// Compile every Android library plugin against SDK 36 so the build works.
subprojects {
    val forceCompileSdk: () -> Unit = {
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.LibraryExtension) {
                ext.compileSdk = 36
            }
        }
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}
""";
  if (!s.contains(anchor)) {
    stderr.writeln('⚠  Could not patch android/build.gradle.kts — set compileSdk 36 for plugins manually.');
    return;
  }
  s = s.replaceFirst(anchor, block + anchor);
  f.writeAsStringSync(s);
  stdout.writeln('✓ android/build.gradle.kts: plugins compile against SDK 36');
}

void _writeProguardRules() {
  final f = File('android/app/proguard-rules.pro');
  if (!Directory('android/app').existsSync()) return;
  final existing = f.existsSync() ? f.readAsStringSync() : '';
  if (existing.contains('io.agora')) return;
  f.writeAsStringSync('$existing\n# Agora RTC SDK\n-keep class io.agora.** { *; }\n-dontwarn io.agora.**\n');
  stdout.writeln('✓ Android R8 keep rules for Agora written');
}

void _patchInfoPlist() {
  final f = File('ios/Runner/Info.plist');
  if (!f.existsSync()) {
    stderr.writeln('⚠  $f not found — skipping iOS permissions.');
    return;
  }
  var plist = f.readAsStringSync();
  final additions = StringBuffer();
  if (!plist.contains('NSCameraUsageDescription')) {
    additions.writeln('\t<key>NSCameraUsageDescription</key>');
    additions.writeln('\t<string>The camera is used for video consultations with the doctor.</string>');
  }
  if (!plist.contains('NSMicrophoneUsageDescription')) {
    additions.writeln('\t<key>NSMicrophoneUsageDescription</key>');
    additions.writeln('\t<string>The microphone is used to talk to the doctor during the video consultation.</string>');
  }
  if (!plist.contains('NSAppTransportSecurity')) {
    // Allows http:// to your local backend while testing. Remove for production (use https).
    additions.writeln('\t<key>NSAppTransportSecurity</key>');
    additions.writeln('\t<dict>');
    additions.writeln('\t\t<key>NSAllowsArbitraryLoads</key>');
    additions.writeln('\t\t<true/>');
    additions.writeln('\t</dict>');
  }
  if (additions.isEmpty) return;
  final i = plist.lastIndexOf('</dict>');
  plist = '${plist.substring(0, i)}$additions${plist.substring(i)}';
  f.writeAsStringSync(plist);
  stdout.writeln('✓ iOS camera/microphone descriptions added');
}

void _patchPodfile() {
  final f = File('ios/Podfile');
  // Flutter 3.24+ on Swift Package Manager has no Podfile; nothing to patch then.
  if (!f.existsSync()) {
    return;
  }
  var pod = f.readAsStringSync();
  var changed = false;
  if (pod.contains("# platform :ios")) {
    pod = pod.replaceFirst(RegExp(r"# platform :ios, '[\d.]+'"), "platform :ios, '13.0'");
    changed = true;
  }
  if (!pod.contains('PERMISSION_CAMERA=1')) {
    const anchor = 'flutter_additional_ios_build_settings(target)';
    if (pod.contains(anchor)) {
      pod = pod.replaceFirst(anchor, '''$anchor
    # permission_handler: enable only the permissions MedConnect uses
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
      ]
    end''');
      changed = true;
    }
  }
  if (changed) {
    f.writeAsStringSync(pod);
    stdout.writeln('✓ iOS Podfile updated for camera/microphone permissions');
  }
}
