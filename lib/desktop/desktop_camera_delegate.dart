import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Desktop fallback for camera requests.
/// image_picker doesn't support camera on desktop by default, so this delegate
/// opens the gallery instead to keep the flow working.
class DesktopCameraDelegate extends ImagePickerCameraDelegate {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<XFile?> takePhoto({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    return _picker.pickImage(
      source: ImageSource.gallery,
    );
  }

  @override
  Future<XFile?> takeVideo({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    return _picker.pickVideo(
      source: ImageSource.gallery,
    );
  }
}
