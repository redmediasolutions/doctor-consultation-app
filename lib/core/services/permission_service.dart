import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Asks for camera + microphone. Returns null when the call can go ahead, or a message to show.
  ///
  /// On iOS the system shows its own camera/microphone prompt (texts in ios/Runner/Info.plist)
  /// the moment the video engine starts, so the call is never blocked here. This keeps iOS
  /// working whether the project uses Swift Package Manager or CocoaPods.
  Future<String?> requestCallPermissions() async {
    if (Platform.isIOS) return null;

    final result = await [Permission.camera, Permission.microphone].request();
    final camera = result[Permission.camera];
    final mic = result[Permission.microphone];

    if ((camera?.isGranted ?? false) && (mic?.isGranted ?? false)) return null;

    if ((camera?.isPermanentlyDenied ?? false) || (mic?.isPermanentlyDenied ?? false)) {
      return 'Camera or microphone access is blocked. Enable it in the device Settings for MedConnect.';
    }
    return 'Camera and microphone access are needed for the video consultation.';
  }

  Future<void> openSettings() => openAppSettings();
}
