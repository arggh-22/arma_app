import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arma_proxy_vpn_client/config/app_config.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_key_model.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/device_auth_response.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/telegram_link_response.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ApiClientErrorType {
  timeout,
  network,
  unauthorized,
  client,
  server,
  malformedResponse,
  unknown,
}

class ApiClientException implements Exception {
  const ApiClientException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final ApiClientErrorType type;
  final String message;
  final int? statusCode;

  bool get isTransient =>
      type == ApiClientErrorType.timeout ||
      type == ApiClientErrorType.network ||
      type == ApiClientErrorType.server;

  @override
  String toString() => 'ApiClientException($type, statusCode: $statusCode)';
}

/// HTTP client for Phase 08 API device auth + key retrieval.
class ApiClient {
  ApiClient({
    required http.Client client,
    this.baseUrl = AppConfig.apiBaseUrl,
    this.apiKey = AppConfig.apiKeyHeaderValue,
    this.connectTimeout = AppConfig.connectTimeout,
    this.readTimeout = AppConfig.readTimeout,
    this.retryDelay = AppConfig.transientRetryDelay,
  }) : _client = client;

  final http.Client _client;
  final String baseUrl;
  final String apiKey;
  final Duration connectTimeout;
  final Duration readTimeout;
  final Duration retryDelay;

  Future<DeviceAuthResponse> authenticateDevice({
    required String deviceId,
    required String osType,
    required String appVersion,
  }) async {
    final response = await _sendWithRetry(
      () => _send(
        method: 'POST',
        path: '/auth/device/',
        headers: {
          AppConfig.apiKeyHeaderName: apiKey,
          'content-type': 'application/json',
        },
        body: <String, dynamic>{
          DeviceAuthApiFields.deviceId: deviceId,
          DeviceAuthApiFields.osType: osType,
          DeviceAuthApiFields.appVersion: appVersion,
        },
      ),
    );
    final payload = _decodeJsonMap(response.body);
    return DeviceAuthResponse.fromJson(payload);
  }

  Future<List<DefaultServerKeyModel>> getKeys(String token) async {
    final response = await _sendWithRetry(
      () => _send(
        method: 'GET',
        path: '/keys/',
        headers: {
          DeviceAuthApiFields.authorization:
              '${DeviceAuthApiFields.authorizationTokenPrefix} $token',
        },
      ),
    );

    final dynamic decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const ApiClientException(
        type: ApiClientErrorType.malformedResponse,
        message: 'Invalid response payload: expected list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiClientException(
              type: ApiClientErrorType.malformedResponse,
              message: 'Invalid key entry payload',
            );
          }
          return DefaultServerKeyModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<TelegramLinkResponse> linkTelegram({
    required String token,
    required String telegramId,
  }) async {
    final response = await _sendWithRetry(
      () => _send(
        method: 'POST',
        path: '/auth/telegram/link/',
        headers: {
          DeviceAuthApiFields.authorization: 'Bearer $token',
          'content-type': 'application/json',
        },
        body: <String, dynamic>{'telegram_id': telegramId},
      ),
    );
    final payload = _decodeJsonMap(response.body);
    return TelegramLinkResponse.fromJson(payload);
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() request,
  ) async {
    ApiClientException? transientFailure;

    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        _logDiagnostics('retry_wait', {
          'attempt': attempt + 1,
          'delay_ms': retryDelay.inMilliseconds,
        });
        await Future<void>.delayed(retryDelay);
      }

      try {
        final response = await request();
        final status = response.statusCode;
        if (status >= 200 && status < 300) {
          return response;
        }

        final exception = _exceptionFromStatus(status);
        if (!_shouldRetry(status: status, attempt: attempt)) {
          _logDiagnostics('response_error', {
            'attempt': attempt + 1,
            'status': status,
            'type': exception.type.name,
            'message': exception.message,
          });
          throw exception;
        }
        transientFailure = exception;
        _logDiagnostics('response_retry', {
          'attempt': attempt + 1,
          'status': status,
          'type': exception.type.name,
          'message': exception.message,
        });
      } on ApiClientException catch (error) {
        _logDiagnostics('api_exception', {
          'attempt': attempt + 1,
          'type': error.type.name,
          'status': error.statusCode,
          'message': error.message,
        });
        if (!error.isTransient || attempt >= 1) {
          rethrow;
        }
        transientFailure = error;
      } on SocketException {
        final exception = const ApiClientException(
          type: ApiClientErrorType.network,
          message: 'Network error while calling VPN API',
        );
        _logDiagnostics('socket_exception', {
          'attempt': attempt + 1,
          'type': exception.type.name,
          'message': exception.message,
        });
        if (attempt >= 1) {
          throw exception;
        }
        transientFailure = exception;
      } on TimeoutException {
        final exception = const ApiClientException(
          type: ApiClientErrorType.timeout,
          message: 'VPN API request timed out',
        );
        _logDiagnostics('timeout_exception', {
          'attempt': attempt + 1,
          'type': exception.type.name,
          'message': exception.message,
        });
        if (attempt >= 1) {
          throw exception;
        }
        transientFailure = exception;
      } on http.ClientException {
        final exception = const ApiClientException(
          type: ApiClientErrorType.network,
          message: 'HTTP client error while calling VPN API',
        );
        _logDiagnostics('http_client_exception', {
          'attempt': attempt + 1,
          'type': exception.type.name,
          'message': exception.message,
        });
        if (attempt >= 1) {
          throw exception;
        }
        transientFailure = exception;
      } on FormatException catch (_) {
        rethrow;
      } catch (_) {
        final exception = const ApiClientException(
          type: ApiClientErrorType.unknown,
          message: 'Unknown VPN API error',
        );
        _logDiagnostics('unknown_exception', {
          'attempt': attempt + 1,
          'type': exception.type.name,
          'message': exception.message,
        });
        if (attempt >= 1) {
          throw exception;
        }
        transientFailure = exception;
      }
    }

    throw transientFailure ??
        const ApiClientException(
          type: ApiClientErrorType.unknown,
          message: 'Unknown VPN API error',
        );
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)
      ..headers.addAll(headers ?? const {})
      ..body = body == null ? '' : jsonEncode(body);

    _logDiagnostics('request', {
      'method': method,
      'url': uri.toString(),
      'headers': _sanitizeHeaders(request.headers),
      'body': _sanitizeRawBody(request.body),
    });

    final streamedResponse =
        await _client.send(request).timeout(connectTimeout);
    final response = await http.Response.fromStream(streamedResponse).timeout(readTimeout);
    _logDiagnostics('response', {
      'method': method,
      'url': uri.toString(),
      'status': response.statusCode,
      'headers': _sanitizeHeaders(response.headers),
      'body': _sanitizeRawBody(response.body),
    });
    return response;
  }

  bool _shouldRetry({required int status, required int attempt}) =>
      attempt == 0 && status >= 500;

  ApiClientException _exceptionFromStatus(int status) {
    if (status == 401) {
      return const ApiClientException(
        type: ApiClientErrorType.unauthorized,
        message: 'Unauthorized request',
        statusCode: 401,
      );
    }
    if (status >= 400 && status < 500) {
      return ApiClientException(
        type: ApiClientErrorType.client,
        message: 'Client request error: $status',
        statusCode: status,
      );
    }
    if (status >= 500) {
      return ApiClientException(
        type: ApiClientErrorType.server,
        message: 'Server request error: $status',
        statusCode: status,
      );
    }
    return ApiClientException(
      type: ApiClientErrorType.unknown,
      message: 'Unexpected response status: $status',
      statusCode: status,
    );
  }

  Map<String, dynamic> _decodeJsonMap(String rawBody) {
    final decoded = _decodeJson(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiClientException(
        type: ApiClientErrorType.malformedResponse,
        message: 'Invalid response payload: expected object',
      );
    }
    return decoded;
  }

  dynamic _decodeJson(String rawBody) {
    try {
      return jsonDecode(rawBody);
    } on FormatException {
      throw const ApiClientException(
        type: ApiClientErrorType.malformedResponse,
        message: 'Response is not valid JSON',
      );
    }
  }

  void _logDiagnostics(String event, Map<String, Object?> payload) {
    if (!AppConfig.apiDiagnosticsEnabled) {
      return;
    }
    debugPrint('[ApiClient][$event] ${jsonEncode(payload)}');
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = <String, String>{};
    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (key == 'authorization' || key == AppConfig.apiKeyHeaderName.toLowerCase()) {
        sanitized[entry.key] = _maskValue(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }

  String _sanitizeRawBody(String rawBody) {
    if (rawBody.isEmpty) {
      return '';
    }
    try {
      final dynamic decoded = jsonDecode(rawBody);
      return jsonEncode(_sanitizeJson(decoded));
    } catch (_) {
      return rawBody;
    }
  }

  dynamic _sanitizeJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, dynamic entryValue) {
        final lower = key.toLowerCase();
        if (lower.contains('token') ||
            lower.contains('device_id') ||
            lower == 'key_body' ||
            lower == 'authorization') {
          return MapEntry<String, dynamic>(key, _maskValue('$entryValue'));
        }
        return MapEntry<String, dynamic>(key, _sanitizeJson(entryValue));
      });
    }
    if (value is List) {
      return value.map(_sanitizeJson).toList(growable: false);
    }
    return value;
  }

  String _maskValue(String raw) {
    if (raw.length <= 8) {
      return '***';
    }
    return '${raw.substring(0, 4)}***${raw.substring(raw.length - 4)}';
  }
}
