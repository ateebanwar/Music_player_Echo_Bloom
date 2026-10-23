import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Web implementation for blob object URL creation and revocation.
class WebBlobUrlHelper {
  static String? createBlobUrl(Uint8List bytes, String mimeType) {
    try {
      final jsArray = [bytes.toJS].toJS;
      final options = web.BlobPropertyBag(type: mimeType);
      final blob = web.Blob(jsArray, options);
      return web.URL.createObjectURL(blob);
    } catch (_) {
      return null;
    }
  }

  static void revokeBlobUrl(String url) {
    try {
      if (url.startsWith('blob:')) {
        web.URL.revokeObjectURL(url);
      }
    } catch (_) {}
  }
}
