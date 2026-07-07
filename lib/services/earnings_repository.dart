import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/earnings.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

abstract class EarningsRepository {
  Future<EarningsDashboard> fetchDashboard({
    EarningsQuery query = const EarningsQuery(),
  });
  Future<PaginatedPayouts> fetchPayouts({int page = 1, int pageSize = 20});
  Future<void> requestPayout(PayoutRequestPayload payload);
}

// ─── Mock repo (fallback when backend is unreachable) ──────────────────────────

class MockEarningsRepository implements EarningsRepository {
  const MockEarningsRepository();

  @override
  Future<EarningsDashboard> fetchDashboard({
    EarningsQuery query = const EarningsQuery(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final List<EarningRecord> all = _earnings
        .where((EarningRecord item) {
          final bool matchesStatus =
              query.status == null || item.status == query.status;
          final bool matchesSearch = query.search.trim().isEmpty ||
              item.role.toLowerCase().contains(query.search.toLowerCase());
          return matchesStatus && matchesSearch;
        })
        .toList(growable: false);
    final int start = ((query.page - 1) * query.pageSize).clamp(0, all.length);
    final int end = (start + query.pageSize).clamp(start, all.length);

    return EarningsDashboard(
      summary: const EarningsSummary(
        totalEarnings: 243820,
        availableBalance: 72150,
        pendingEarnings: 18400,
        withdrawnAmount: 136200,
      ),
      history: PaginatedEarnings(
        items: all.sublist(start, end),
        page: query.page,
        pageSize: query.pageSize,
        total: all.length,
        hasMore: end < all.length,
      ),
    );
  }

  @override
  Future<PaginatedPayouts> fetchPayouts({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final int start = ((page - 1) * pageSize).clamp(0, _payouts.length);
    final int end = (start + pageSize).clamp(start, _payouts.length);
    return PaginatedPayouts(
      items: _payouts.sublist(start, end),
      page: page,
      pageSize: pageSize,
      total: _payouts.length,
      hasMore: end < _payouts.length,
    );
  }

  @override
  Future<void> requestPayout(PayoutRequestPayload payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (payload.amount != null && payload.amount! <= 0) {
      throw Exception('Enter a valid payout amount.');
    }
  }

  static final List<EarningRecord> _earnings = <EarningRecord>[
    EarningRecord(
      id: 'earn-1008',
      date: DateTime(2026, 6, 24),
      amount: 7728,
      role: 'SHOP_OWNER',
      status: EarningStatus.available,
    ),
    EarningRecord(
      id: 'earn-1007',
      date: DateTime(2026, 6, 23),
      amount: 5704,
      role: 'SHOP_OWNER',
      status: EarningStatus.pendingPayout,
    ),
    EarningRecord(
      id: 'earn-1006',
      date: DateTime(2026, 6, 22),
      amount: 9752,
      role: 'SHOP_OWNER',
      status: EarningStatus.available,
    ),
    EarningRecord(
      id: 'earn-1005',
      date: DateTime(2026, 6, 20),
      amount: 3864,
      role: 'SHOP_OWNER',
      status: EarningStatus.paidOut,
    ),
  ];

  static final List<PayoutRecord> _payouts = <PayoutRecord>[
    PayoutRecord(
      id: 'pay-208',
      requestDate: DateTime(2026, 6, 24),
      amount: 17070,
      status: PayoutStatus.processing,
      payoutMethod: 'TELEBIRR',
      payoutAccount: '+251 91 *** 4821',
      providerReference: 'TB-882104',
    ),
    PayoutRecord(
      id: 'pay-207',
      requestDate: DateTime(2026, 6, 15),
      amount: 32000,
      status: PayoutStatus.completed,
      payoutMethod: 'BANK',
      payoutAccount: '**** 4388',
      providerReference: 'BNK-44902',
    ),
    PayoutRecord(
      id: 'pay-206',
      requestDate: DateTime(2026, 6, 5),
      amount: 18500,
      status: PayoutStatus.rejected,
      payoutMethod: 'TELEBIRR',
      payoutAccount: '+251 91 *** 1002',
      providerReference: 'TB-881002',
    ),
  ];
}

// ─── Fallback wrapper (tries backend first, falls back to mock) ────────────────

class FallbackEarningsRepository implements EarningsRepository {
  const FallbackEarningsRepository({
    required this.primary,
    required this.fallback,
  });

  final EarningsRepository primary;
  final EarningsRepository fallback;

  @override
  Future<EarningsDashboard> fetchDashboard({
    EarningsQuery query = const EarningsQuery(),
  }) async {
    try {
      return await primary.fetchDashboard(query: query);
    } catch (_) {
      return fallback.fetchDashboard(query: query);
    }
  }

  @override
  Future<PaginatedPayouts> fetchPayouts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await primary.fetchPayouts(page: page, pageSize: pageSize);
    } catch (_) {
      return fallback.fetchPayouts(page: page, pageSize: pageSize);
    }
  }

  @override
  Future<void> requestPayout(PayoutRequestPayload payload) async {
    // No fallback for a write operation — a mock "success" would be misleading.
    await primary.requestPayout(payload);
  }
}

// ─── Backend repo (talks to the real Django endpoints) ─────────────────────────

class BackendEarningsRepository implements EarningsRepository {
  BackendEarningsRepository({String? baseUrl, this.client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  @override
  Future<EarningsDashboard> fetchDashboard({
    EarningsQuery query = const EarningsQuery(),
  }) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      // Summary: GET /payment/earnings/dashboard/
      final http.Response summaryResponse = await activeClient
          .get(_endpoint('/payment/earnings/dashboard/'), headers: _headers())
          .timeout(const Duration(seconds: 20));
      final Map<String, dynamic> summaryJson = _decodeResponse(summaryResponse);
      final EarningsSummary summary = EarningsSummary.fromJson(summaryJson);

      // History: GET /payment/earnings/history/
      final http.Response historyResponse = await activeClient
          .get(
            _endpoint('/payment/earnings/history/', query.toQueryParameters()),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));
      final Map<String, dynamic> historyJson = _decodeResponse(historyResponse);
      final PaginatedEarnings history = PaginatedEarnings.fromJson(
        historyJson,
        page: query.page,
        pageSize: query.pageSize,
      );

      return EarningsDashboard(summary: summary, history: history);
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  @override
  Future<PaginatedPayouts> fetchPayouts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final http.Response response = await activeClient
          .get(
            _endpoint('/payment/payouts/history/', <String, String>{
              'page': page.toString(),
              'page_size': pageSize.toString(),
            }),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data = _decodeResponse(response);
      final Map<String, dynamic> historyJson =
          data['history'] is Map<String, dynamic>
              ? data['history'] as Map<String, dynamic>
              : data;
      return PaginatedPayouts.fromJson(historyJson, page: page, pageSize: pageSize);
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  @override
  Future<void> requestPayout(PayoutRequestPayload payload) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final http.Response response = await activeClient
          .post(
            _endpoint('/payment/payouts/request/'),
            headers: _headers(contentType: true),
            body: jsonEncode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 20));
      _decodeResponse(response);
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  Map<String, String> _headers({bool contentType = false}) {
    final String? token = AuthSessionStore.token;
    if (token == null) {
      throw Exception('Not authenticated. Please login first.');
    }
    return <String, String>{
      'Accept': 'application/json',
      if (contentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Uri _endpoint(String path, [Map<String, String>? queryParameters]) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Map<String, dynamic> body = _decodeBody(response.body);
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromErrorBody(body, response.statusCode));
    }
    return body;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final Object? decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected a JSON object.');
  }

  String _messageFromErrorBody(Map<String, dynamic> body, int statusCode) {
    // Django views in this app commonly return {"detail": "..."} on error.
    final Object? detail = body['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty) {
      return detail.join(', ');
    }
    // DRF serializer validation errors: {"field": ["msg1", "msg2"], ...}
    final List<String> fieldErrors = <String>[];
    body.forEach((String key, dynamic value) {
      if (value is List) {
        fieldErrors.addAll(value.map((dynamic v) => '$key: $v'));
      }
    });
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.join('; ');
    }
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Payment request failed with status $statusCode.';
  }
}