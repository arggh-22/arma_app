import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and replaces geo rule files used by Xray core.
///
/// Files are written to `<filesDir>/xray-assets/` so native
/// `XrayCoreManager.initCoreEnv()` picks them up on the next VPN start.
class RulesUpdateService {
  static const _geoipUrl =
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat';
  static const _geositeUrl =
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat';

  static const _timeout = Duration(seconds: 20);

  Future<int> updateRules() async {
    final supportDir = await getApplicationSupportDirectory();
    final targetDir = Directory('${supportDir.path}/xray-assets');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final downloads = <String, String>{
      'geoip.dat': _geoipUrl,
      'geosite.dat': _geositeUrl,
    };

    var updatedCount = 0;
    final client = http.Client();
    try {
      for (final entry in downloads.entries) {
        final response = await client.get(Uri.parse(entry.value)).timeout(_timeout);
        if (response.statusCode != 200) {
          throw HttpException(
            'Failed to download ${entry.key}: HTTP ${response.statusCode}',
          );
        }
        if (response.bodyBytes.isEmpty) {
          throw const HttpException('Downloaded rule file is empty');
        }

        final filePath = '${targetDir.path}/${entry.key}';
        final tempPath = '$filePath.new';
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(response.bodyBytes, flush: true);

        final targetFile = File(filePath);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(filePath);
        updatedCount++;
      }
    } finally {
      client.close();
    }

    return updatedCount;
  }
}

