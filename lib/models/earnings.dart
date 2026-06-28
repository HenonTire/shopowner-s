enum EarningStatus { pending, available, withdrawn, refunded, cancelled }

enum PayoutStatus { pending, approved, processing, paid, failed, rejected }

class EarningsQuery {
  const EarningsQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.status,
    this.from,
    this.to,
    this.ordering = '-date',
  });

  final int page;
  final int pageSize;
  final String search;
  final EarningStatus? status;
  final DateTime? from;
  final DateTime? to;
  final String ordering;

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'ordering': ordering,
    };
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null) {
      params['status'] = status!.apiValue;
    }
    if (from != null) {
      params['from'] = _dateOnly(from!);
    }
    if (to != null) {
      params['to'] = _dateOnly(to!);
    }
    return params;
  }
}

class EarningsDashboard {
  const EarningsDashboard({
    required this.summary,
    required this.history,
    required this.chart,
    required this.payoutAccounts,
    required this.minimumWithdrawal,
    required this.maximumWithdrawal,
  });

  final EarningsSummary summary;
  final PaginatedEarnings history;
  final List<EarningsChartPoint> chart;
  final List<PayoutAccount> payoutAccounts;
  final double minimumWithdrawal;
  final double maximumWithdrawal;

  factory EarningsDashboard.fromJson(Map<String, dynamic> json) {
    return EarningsDashboard(
      summary: EarningsSummary.fromJson(_map(json['summary'])),
      history: PaginatedEarnings.fromJson(
        _map(json['history'] ?? json['earnings']),
      ),
      chart: _list(json['chart'] ?? json['chart_points'])
          .whereType<Map<String, dynamic>>()
          .map(EarningsChartPoint.fromJson)
          .toList(growable: false),
      payoutAccounts: _list(json['payout_accounts'] ?? json['accounts'])
          .whereType<Map<String, dynamic>>()
          .map(PayoutAccount.fromJson)
          .toList(growable: false),
      minimumWithdrawal: _double(
        json['minimum_withdrawal'] ?? json['min_withdrawal'],
        fallback: 500,
      ),
      maximumWithdrawal: _double(
        json['maximum_withdrawal'] ?? json['max_withdrawal'],
        fallback: 250000,
      ),
    );
  }
}

class EarningsSummary {
  const EarningsSummary({
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingEarnings,
    required this.withdrawnAmount,
    required this.processingPayouts,
  });

  final double totalEarnings;
  final double availableBalance;
  final double pendingEarnings;
  final double withdrawnAmount;
  final double processingPayouts;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: _double(json['total_earnings']),
      availableBalance: _double(json['available_balance']),
      pendingEarnings: _double(
        json['pending_earnings'] ?? json['pending_balance'],
      ),
      withdrawnAmount: _double(json['withdrawn_amount'] ?? json['withdrawn']),
      processingPayouts: _double(
        json['processing_payouts'] ?? json['processing_amount'],
      ),
    );
  }
}

class EarningsChartPoint {
  const EarningsChartPoint({required this.label, required this.amount});

  final String label;
  final double amount;

  factory EarningsChartPoint.fromJson(Map<String, dynamic> json) {
    return EarningsChartPoint(
      label:
          json['label']?.toString() ??
          json['day_label']?.toString() ??
          json['date']?.toString() ??
          '',
      amount: _double(
        json['amount'] ?? json['earnings'] ?? json['net_earnings'],
      ),
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

  factory PaginatedEarnings.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pagination = _map(json['pagination']);
    final List<dynamic> rawItems = _list(
      json['results'] ?? json['data'] ?? json['items'] ?? json['earnings'],
    );
    final int page = _int(pagination['page'] ?? json['page'], fallback: 1);
    final int pageSize = _int(
      pagination['page_size'] ?? json['page_size'],
      fallback: rawItems.length,
    );
    final int total = _int(
      pagination['total'] ?? json['count'] ?? json['total'],
      fallback: rawItems.length,
    );
    return PaginatedEarnings(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(EarningRecord.fromJson)
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      total: total,
      hasMore:
          pagination['has_more'] == true ||
          json['next'] != null ||
          (page * pageSize) < total,
    );
  }
}

class EarningRecord {
  const EarningRecord({
    required this.id,
    required this.date,
    required this.sourceOrder,
    required this.customer,
    required this.commission,
    required this.grossAmount,
    required this.platformFee,
    required this.netEarnings,
    required this.status,
  });

  final String id;
  final DateTime date;
  final String sourceOrder;
  final String customer;
  final double commission;
  final double grossAmount;
  final double platformFee;
  final double netEarnings;
  final EarningStatus status;

  factory EarningRecord.fromJson(Map<String, dynamic> json) {
    return EarningRecord(
      id: json['id']?.toString() ?? '',
      date:
          DateTime.tryParse(
            json['date']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      sourceOrder:
          json['source_order']?.toString() ??
          json['order']?.toString() ??
          json['order_id']?.toString() ??
          '',
      customer:
          json['customer']?.toString() ??
          json['customer_name']?.toString() ??
          '',
      commission: _double(json['commission'] ?? json['commission_amount']),
      grossAmount: _double(json['gross_amount'] ?? json['gross']),
      platformFee: _double(json['platform_fee'] ?? json['fee']),
      netEarnings: _double(
        json['net_earnings'] ?? json['net_amount'] ?? json['amount'],
      ),
      status: earningStatusFromApi(json['status']?.toString()),
    );
  }
}

class PayoutAccount {
  const PayoutAccount({
    required this.id,
    required this.method,
    required this.label,
    required this.maskedAccount,
    required this.isVerified,
  });

  final String id;
  final String method;
  final String label;
  final String maskedAccount;
  final bool isVerified;

  factory PayoutAccount.fromJson(Map<String, dynamic> json) {
    return PayoutAccount(
      id: json['id']?.toString() ?? '',
      method: json['method']?.toString() ?? json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      maskedAccount:
          json['masked_account']?.toString() ??
          json['account_display']?.toString() ??
          '',
      isVerified: json['is_verified'] == true || json['verified'] == true,
    );
  }
}

class PayoutRequestPayload {
  const PayoutRequestPayload({
    required this.amount,
    required this.method,
    required this.accountId,
  });

  final double amount;
  final String method;
  final String accountId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'method': method,
      'account_id': accountId,
    };
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

  factory PaginatedPayouts.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pagination = _map(json['pagination']);
    final List<dynamic> rawItems = _list(
      json['results'] ?? json['data'] ?? json['items'] ?? json['payouts'],
    );
    final int page = _int(pagination['page'] ?? json['page'], fallback: 1);
    final int pageSize = _int(
      pagination['page_size'] ?? json['page_size'],
      fallback: rawItems.length,
    );
    final int total = _int(
      pagination['total'] ?? json['count'] ?? json['total'],
      fallback: rawItems.length,
    );
    return PaginatedPayouts(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PayoutRecord.fromJson)
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      total: total,
      hasMore:
          pagination['has_more'] == true ||
          json['next'] != null ||
          (page * pageSize) < total,
    );
  }
}

class PayoutRecord {
  const PayoutRecord({
    required this.id,
    required this.requestDate,
    required this.amount,
    required this.fees,
    required this.netAmount,
    required this.method,
    required this.status,
    required this.transactionReference,
    this.processedDate,
  });

  final String id;
  final DateTime requestDate;
  final double amount;
  final double fees;
  final double netAmount;
  final String method;
  final PayoutStatus status;
  final String transactionReference;
  final DateTime? processedDate;

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id']?.toString() ?? '',
      requestDate:
          DateTime.tryParse(
            json['request_date']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      amount: _double(json['amount']),
      fees: _double(json['fees'] ?? json['fee']),
      netAmount: _double(json['net_amount']),
      method: json['method']?.toString() ?? '',
      status: payoutStatusFromApi(json['status']?.toString()),
      transactionReference:
          json['transaction_reference']?.toString() ??
          json['reference']?.toString() ??
          '',
      processedDate: DateTime.tryParse(
        json['processed_date']?.toString() ??
            json['processed_at']?.toString() ??
            '',
      ),
    );
  }
}

extension EarningStatusLabel on EarningStatus {
  String get label {
    switch (this) {
      case EarningStatus.pending:
        return 'Pending';
      case EarningStatus.available:
        return 'Available';
      case EarningStatus.withdrawn:
        return 'Withdrawn';
      case EarningStatus.refunded:
        return 'Refunded';
      case EarningStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get apiValue => name;
}

extension PayoutStatusLabel on PayoutStatus {
  String get label {
    switch (this) {
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.approved:
        return 'Approved';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.paid:
        return 'Paid';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.rejected:
        return 'Rejected';
    }
  }

  String get apiValue => name;
}

EarningStatus earningStatusFromApi(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'available':
      return EarningStatus.available;
    case 'withdrawn':
      return EarningStatus.withdrawn;
    case 'refunded':
      return EarningStatus.refunded;
    case 'cancelled':
    case 'canceled':
      return EarningStatus.cancelled;
    case 'pending':
    default:
      return EarningStatus.pending;
  }
}

PayoutStatus payoutStatusFromApi(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'approved':
      return PayoutStatus.approved;
    case 'processing':
      return PayoutStatus.processing;
    case 'paid':
      return PayoutStatus.paid;
    case 'failed':
      return PayoutStatus.failed;
    case 'rejected':
      return PayoutStatus.rejected;
    case 'pending':
    default:
      return PayoutStatus.pending;
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
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

String _dateOnly(DateTime value) {
  return value.toIso8601String().split('T').first;
}
