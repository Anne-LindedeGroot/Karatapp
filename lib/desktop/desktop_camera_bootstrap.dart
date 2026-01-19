import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'desktop_camera_delegate.dart';
import 'desktop_platform_utils.dart';

void configureDesktopImagePickerCameraDelegate() {
  if (!DesktopPlatformUtils.isDesktopPlatform()) {
    return;
  }

  final instance = ImagePickerPlatform.instance;
  if (instance is CameraDelegatingImagePickerPlatform) {
    instance.cameraDelegate = DesktopCameraDelegate();
  }
}
