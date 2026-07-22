import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

class IdentityVerificationStatus {
  const IdentityVerificationStatus({
    required this.status,
    required this.documentType,
    required this.documentNumber,
    required this.reviewNotes,
  });

  final String status; // PENDING, APPROVED, REJECTED
  final String documentType;
  final String documentNumber;
  final String reviewNotes;

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';

  factory IdentityVerificationStatus.fromJson(Map<String, dynamic> json) {
    return IdentityVerificationStatus(
      status: json['status']?.toString() ?? 'PENDING',
      documentType: json['document_type']?.toString() ?? '',
      documentNumber: json['document_number']?.toString() ?? '',
      reviewNotes: json['review_notes']?.toString() ?? '',
    );
  }
}

class IdentityVerificationRepository {
  IdentityVerificationRepository({String? baseUrl, this.client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  Uri _endpoint(String path) {
    final String base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path');
  }
  Future<void> deleteMyData() async {
    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated.');

    final http.Client activeClient = client ?? http.Client();
    try {
      final http.Response response = await activeClient
          .delete(
            _endpoint('/auth/identity-verification/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete verification data (${response.statusCode}): ${response.body}');
      }
    } finally {
      if (client == null) activeClient.close();
    }
  }

  /// Returns null if the user hasn't submitted anything yet (404).
  Future<IdentityVerificationStatus?> fetchMyStatus() async {
    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated.');

    final http.Client activeClient = client ?? http.Client();
    try {
      final http.Response response = await activeClient
          .get(
            _endpoint('/auth/identity-verification/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch verification status (${response.statusCode}): ${response.body}');
      }

      return IdentityVerificationStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } finally {
      if (client == null) activeClient.close();
    }
  }

  Future<IdentityVerificationStatus> submit({
    required String documentType,
    required String documentNumber,
    required Uint8List frontImageBytes,
    required String frontImageName,
    Uint8List? backImageBytes,
    String? backImageName,
    required Uint8List selfieImageBytes,
    required String selfieImageName,
  }) async {
    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated.');

    final http.Client activeClient = client ?? http.Client();
    try {
      final http.MultipartRequest request =
          http.MultipartRequest('POST', _endpoint('/auth/identity-verification/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['document_type'] = documentType;
      request.fields['document_number'] = documentNumber;

      request.files.add(http.MultipartFile.fromBytes('front_image', frontImageBytes, filename: frontImageName));
      request.files.add(http.MultipartFile.fromBytes('selfie_image', selfieImageBytes, filename: selfieImageName));
      if (backImageBytes != null && backImageName != null) {
        request.files.add(http.MultipartFile.fromBytes('back_image', backImageBytes, filename: backImageName));
      }

      final http.StreamedResponse streamed = await request.send().timeout(const Duration(seconds: 30));
      final http.Response response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to submit verification (${response.statusCode}): ${response.body}');
      }

      return IdentityVerificationStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } finally {
      if (client == null) activeClient.close();
    }
  }
}