/// DTO for `/auth/telegram/link/` response payload.
class TelegramLinkResponse {
  const TelegramLinkResponse({required this.detail, this.status, this.code});

  final String detail;
  final String? status;
  final String? code;

  factory TelegramLinkResponse.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'];
    final status = json['status'];
    final code = json['code'];

    if (detail is! String || detail.isEmpty) {
      throw const FormatException('Invalid telegram link payload: detail');
    }
    if (status != null && status is! String) {
      throw const FormatException('Invalid telegram link payload: status');
    }
    if (code != null && code is! String) {
      throw const FormatException('Invalid telegram link payload: code');
    }

    return TelegramLinkResponse(detail: detail, status: status, code: code);
  }
}
