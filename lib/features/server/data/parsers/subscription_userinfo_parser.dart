/// Parsed result of the `subscription-userinfo` HTTP response header.
///
/// The header format is:
///   `upload=1234; download=5678; total=10000; expire=1700000000`
///
/// All fields are optional — partial headers are handled gracefully.
/// The `expire` value is a Unix timestamp in seconds.
class SubscriptionUserinfo {
  /// Upload bytes consumed.
  final int? uploadBytes;

  /// Download bytes consumed.
  final int? downloadBytes;

  /// Total bandwidth quota in bytes.
  final int? totalBytes;

  /// Subscription expiration date.
  final DateTime? expireDate;

  const SubscriptionUserinfo({
    this.uploadBytes,
    this.downloadBytes,
    this.totalBytes,
    this.expireDate,
  });
}

/// Parses the `subscription-userinfo` HTTP response header.
///
/// Returns null if [header] is null or empty.
///
/// Example header value:
///   `upload=1234; download=5678; total=10000; expire=1700000000`
SubscriptionUserinfo? parseSubscriptionUserinfo(String? header) {
  if (header == null || header.isEmpty) return null;

  int? upload, download, total;
  DateTime? expire;

  for (final part in header.split(';').map((p) => p.trim())) {
    final kv = part.split('=');
    if (kv.length != 2) continue;

    final key = kv[0].trim().toLowerCase();
    final value = kv[1].trim();

    switch (key) {
      case 'upload':
        upload = int.tryParse(value);
      case 'download':
        download = int.tryParse(value);
      case 'total':
        total = int.tryParse(value);
      case 'expire':
        final ts = int.tryParse(value);
        if (ts != null) {
          expire = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        }
    }
  }

  return SubscriptionUserinfo(
    uploadBytes: upload,
    downloadBytes: download,
    totalBytes: total,
    expireDate: expire,
  );
}
