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

class MockEarningsRepository implements EarningsRepository {
  const MockEarningsRepository();

  @override
  Future<EarningsDashboard> fetchDashboard({
    EarningsQuery query = const EarningsQuery(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final List<EarningRecord> all = _earnings
        .where((EarningRecord item) {
          final bool matchesStatus =
              query.status == null || item.status == query.status;
          final bool matchesSearch =
              query.search.trim().isEmpty ||
              item.sourceOrder.toLowerCase().contains(
                query.search.toLowerCase(),
              ) ||
              item.customer.toLowerCase().contains(query.search.toLowerCase());
          final bool matchesFrom =
              query.from == null || !item.date.isBefore(query.from!);
          final bool matchesTo =
              query.to == null || !item.date.isAfter(query.to!);
          return matchesStatus && matchesSearch && matchesFrom && matchesTo;
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
        processingPayouts: 17070,
      ),
      history: PaginatedEarnings(
        items: all.sublist(start, end),
        page: query.page,
        pageSize: query.pageSize,
        total: all.length,
        hasMore: end < all.length,
      ),
      chart: const <EarningsChartPoint>[
        EarningsChartPoint(label: 'Mon', amount: 11800),
        EarningsChartPoint(label: 'Tue', amount: 9700),
        EarningsChartPoint(label: 'Wed', amount: 13250),
        EarningsChartPoint(label: 'Thu', amount: 12400),
        EarningsChartPoint(label: 'Fri', amount: 18100),
        EarningsChartPoint(label: 'Sat', amount: 21400),
        EarningsChartPoint(label: 'Sun', amount: 15100),
      ],
      payoutAccounts: const <PayoutAccount>[
        PayoutAccount(
          id: 'acct-telebirr',
          method: 'mobile_money',
          label: 'Telebirr',
          maskedAccount: '+251 91 *** 4821',
          isVerified: true,
        ),
        PayoutAccount(
          id: 'acct-bank',
          method: 'bank_transfer',
          label: 'Commercial Bank',
          maskedAccount: '**** 4388',
          isVerified: true,
        ),
      ],
      minimumWithdrawal: 500,
      maximumWithdrawal: 250000,
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
    if (payload.amount <= 0) {
      throw Exception('Enter a valid payout amount.');
    }
  }

  static final List<EarningRecord> _earnings = <EarningRecord>[
    EarningRecord(
      id: 'earn-1008',
      date: DateTime(2026, 6, 24),
      sourceOrder: 'ORD-3108',
      customer: 'Marta Tesfaye',
      commission: 420,
      grossAmount: 8400,
      platformFee: 252,
      netEarnings: 7728,
      status: EarningStatus.available,
    ),
    EarningRecord(
      id: 'earn-1007',
      date: DateTime(2026, 6, 23),
      sourceOrder: 'ORD-3101',
      customer: 'Dawit Alemu',
      commission: 310,
      grossAmount: 6200,
      platformFee: 186,
      netEarnings: 5704,
      status: EarningStatus.pending,
    ),
    EarningRecord(
      id: 'earn-1006',
      date: DateTime(2026, 6, 22),
      sourceOrder: 'ORD-3095',
      customer: 'Selam Berhanu',
      commission: 530,
      grossAmount: 10600,
      platformFee: 318,
      netEarnings: 9752,
      status: EarningStatus.available,
    ),
    EarningRecord(
      id: 'earn-1005',
      date: DateTime(2026, 6, 20),
      sourceOrder: 'ORD-3079',
      customer: 'Noah Getachew',
      commission: 210,
      grossAmount: 4200,
      platformFee: 126,
      netEarnings: 3864,
      status: EarningStatus.withdrawn,
    ),
    EarningRecord(
      id: 'earn-1004',
      date: DateTime(2026, 6, 18),
      sourceOrder: 'ORD-3068',
      customer: 'Hana Mohammed',
      commission: 165,
      grossAmount: 3300,
      platformFee: 99,
      netEarnings: 3036,
      status: EarningStatus.cancelled,
    ),
  ];

  static final List<PayoutRecord> _payouts = <PayoutRecord>[
    PayoutRecord(
      id: 'pay-208',
      requestDate: DateTime(2026, 6, 24),
      amount: 17070,
      fees: 120,
      netAmount: 16950,
      method: 'Mobile Money',
      status: PayoutStatus.processing,
      transactionReference: 'TB-882104',
    ),
    PayoutRecord(
      id: 'pay-207',
      requestDate: DateTime(2026, 6, 15),
      amount: 32000,
      fees: 180,
      netAmount: 31820,
      method: 'Bank Transfer',
      status: PayoutStatus.paid,
      transactionReference: 'BNK-44902',
      processedDate: DateTime(2026, 6, 16),
    ),
    PayoutRecord(
      id: 'pay-206',
      requestDate: DateTime(2026, 6, 5),
      amount: 18500,
      fees: 95,
      netAmount: 18405,
      method: 'Mobile Money',
      status: PayoutStatus.rejected,
      transactionReference: 'TB-881002',
      processedDate: DateTime(2026, 6, 5),
    ),
  ];
}

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
    try {
      await primary.requestPayout(payload);
    } catch (_) {
      await fallback.requestPayout(payload);
    }
  }
}

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
      final http.Response response = await activeClient
          .get(
            _endpoint('/payment/earnings/', query.toQueryParameters()),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data = _decodeResponse(response);
      return EarningsDashboard.fromJson(data);
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
            _endpoint('/payment/payouts/', <String, String>{
              'page': page.toString(),
              'page_size': pageSize.toString(),
            }),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data = _decodeResponse(response);
      return PaginatedPayouts.fromJson(data);
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
            _endpoint('/payment/payouts/'),
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
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Payment request failed with status $statusCode.';
  }
}
