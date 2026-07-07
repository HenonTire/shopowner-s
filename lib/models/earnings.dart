enum EarningStatus { available, pendingPayout, paidOut }

enum PayoutStatus { requested, processing, completed, failed, rejected }

class EarningsQuery {
  const EarningsQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.status,
  });

  final int page;
  final int pageSize;
  final String search;
  final EarningStatus? status;

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null) {
      params['status'] = status!.apiValue;
    }
    return params;
  }

  EarningsQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    EarningStatus? status,
    bool clearStatus = false,
  }) {
    return EarningsQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class EarningsSummary {
  const EarningsSummary({
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingEarnings,
    required this.withdrawnAmount,
  });

  final double totalEarnings;
  final double availableBalance;
  final double pendingEarnings;
  final double withdrawnAmount;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: _double(json['total']),
      availableBalance: _double(json['available']),
      pendingEarnings: _double(json['pending']),
      withdrawnAmount: _double(json['withdrawn']),
    );
  }
}

class EarningRecord {
  const EarningRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.role,
    required this.status,
    this.orderId,
    this.paymentId,
  });

  final String id;
  final DateTime date;
  final double amount;
  final String role;
  final EarningStatus status;
  final String? orderId;
  final String? paymentId;

  factory EarningRecord.fromJson(Map<String, dynamic> json) {
    return EarningRecord(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      amount: _double(json['amount']),
      role: json['role']?.toString() ?? '',
      status: earningStatusFromApi(json['status']?.toString()),
      orderId: json['order']?.toString(),
      paymentId: json['payment']?.toString(),
    );
  }
}

class PaginatedEarnings {
  const PaginatedEarnings({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<EarningRecord> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  factory PaginatedEarnings.fromJson(
    Map<String, dynamic> json, {
    required int page,
    required int pageSize,
  }) {
    final List<dynamic> rawItems = _list(json['results']);
    final int total = _int(json['count'], fallback: rawItems.length);
    return PaginatedEarnings(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(EarningRecord.fromJson)
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      total: total,
      hasMore: json['next'] != null,
    );
  }

  static const PaginatedEarnings empty = PaginatedEarnings(
    items: <EarningRecord>[],
    page: 1,
    pageSize: 20,
    total: 0,
    hasMore: false,
  );
}

class EarningsDashboard {
  const EarningsDashboard({
    required this.summary,
    required this.history,
  });

  final EarningsSummary summary;
  final PaginatedEarnings history;
}

class PayoutRequestPayload {
  const PayoutRequestPayload({
    this.amount,
    this.idempotencyKey,
  });

  /// Leave null to request a payout of the full available balance.
  final double? amount;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'confirm': true,
      if (amount != null) 'amount': amount!.toStringAsFixed(2),
      if (idempotencyKey != null && idempotencyKey!.trim().isNotEmpty)
        'idempotency_key': idempotencyKey!.trim(),
    };
  }
}

class PayoutRecord {
  const PayoutRecord({
    required this.id,
    required this.requestDate,
    required this.amount,
    required this.status,
    required this.payoutMethod,
    required this.payoutAccount,
    this.providerReference,
    this.orderId,
    this.paymentId,
  });

  final String id;
  final DateTime requestDate;
  final double amount;
  final PayoutStatus status;
  final String payoutMethod;
  final String payoutAccount;
  final String? providerReference;
  final String? orderId;
  final String? paymentId;

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id']?.toString() ?? '',
      requestDate: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      amount: _double(json['amount']),
      status: payoutStatusFromApi(json['status']?.toString()),
      payoutMethod: json['payout_method']?.toString() ?? '',
      payoutAccount: json['payout_account']?.toString() ?? '',
      providerReference: json['provider_reference']?.toString(),
      orderId: json['order']?.toString(),
      paymentId: json['payment']?.toString(),
    );
  }
}

class PaginatedPayouts {
  const PaginatedPayouts({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<PayoutRecord> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  factory PaginatedPayouts.fromJson(
    Map<String, dynamic> json, {
    required int page,
    required int pageSize,
  }) {
    final List<dynamic> rawItems = _list(json['results']);
    final int total = _int(json['count'], fallback: rawItems.length);
    return PaginatedPayouts(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PayoutRecord.fromJson)
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      total: total,
      hasMore: json['next'] != null,
    );
  }
}

extension EarningStatusLabel on EarningStatus {
  String get label {
    switch (this) {
      case EarningStatus.available:
        return 'Available';
      case EarningStatus.pendingPayout:
        return 'Pending Payout';
      case EarningStatus.paidOut:
        return 'Paid Out';
    }
  }

  String get apiValue {
    switch (this) {
      case EarningStatus.available:
        return 'AVAILABLE';
      case EarningStatus.pendingPayout:
        return 'PENDING_PAYOUT';
      case EarningStatus.paidOut:
        return 'PAID_OUT';
    }
  }
}

extension PayoutStatusLabel on PayoutStatus {
  String get label {
    switch (this) {
      case PayoutStatus.requested:
        return 'Requested';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.rejected:
        return 'Rejected';
    }
  }

  String get apiValue {
    switch (this) {
      case PayoutStatus.requested:
        return 'REQUESTED';
      case PayoutStatus.processing:
        return 'PROCESSING';
      case PayoutStatus.completed:
        return 'COMPLETED';
      case PayoutStatus.failed:
        return 'FAILED';
      case PayoutStatus.rejected:
        return 'REJECTED';
    }
  }
}

EarningStatus earningStatusFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'PENDING_PAYOUT':
      return EarningStatus.pendingPayout;
    case 'PAID_OUT':
      return EarningStatus.paidOut;
    case 'AVAILABLE':
    default:
      return EarningStatus.available;
  }
}

PayoutStatus payoutStatusFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'PROCESSING':
      return PayoutStatus.processing;
    case 'COMPLETED':
      return PayoutStatus.completed;
    case 'FAILED':
      return PayoutStatus.failed;
    case 'REJECTED':
      return PayoutStatus.rejected;
    case 'REQUESTED':
    default:
      return PayoutStatus.requested;
  }
}

List<dynamic> _list(Object? value) {
  return value is List<dynamic> ? value : <dynamic>[];
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '')) ?? fallback;
  }
  return fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}