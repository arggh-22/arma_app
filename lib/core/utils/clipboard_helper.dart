import 'package:flutter/services.dart';

/// Helper class for clipboard operations.
///
/// Wraps [Clipboard] API to provide a clean async interface
/// for reading text from the system clipboard.
class ClipboardHelper {
  ClipboardHelper._();

  /// Reads text from the system clipboard.
  ///
  /// Returns the trimmed text, or `null` if the clipboard is empty
  /// or does not contain text.
  static Future<String?> getText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim();
  }
}
