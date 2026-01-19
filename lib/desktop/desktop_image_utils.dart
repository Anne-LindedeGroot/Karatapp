import 'dart:io';
import 'package:flutter/material.dart';
import 'desktop_camera_screen.dart';
import 'desktop_platform_utils.dart';

class DesktopImageUtils {
  static Future<File?> captureImageWithCamera({BuildContext? context}) async {
    if (!DesktopPlatformUtils.isDesktopPlatform()) {
      return null;
    }

    if (context == null) {
      debugPrint('Desktop camera requires context to open camera screen');
      return null;
    }

    return DesktopCameraScreen.capture(context);
  }
}
