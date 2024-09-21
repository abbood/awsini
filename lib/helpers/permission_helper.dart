import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static bool areRequiredPermissionsGranted(PermissionStatus photoStatus, PermissionStatus storageStatus) {
    if (Platform.isAndroid) {
      return photoStatus.isGranted && storageStatus.isGranted;
    } else if (Platform.isIOS) {
      return photoStatus.isGranted;
    }
    return false; // For other platforms, assuming permissions are not granted
  }
}
