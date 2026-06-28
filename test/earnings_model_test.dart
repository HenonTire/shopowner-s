import 'package:flutter_test/flutter_test.dart';
import 'package:shop_manager/models/earnings.dart';

void main() {
  group('EarningsDashboard', () {
    test('parses summary, chart, accounts, and DRF paginated history', () {
      final EarningsDashboard dashboard = EarningsDashboard.fromJson(
        <String, dynamic>{
          'summary': <String, dynamic>{
            'total_earnings': '12000.50',
            'available_balance': 8000,
            'pending_balance': 1500,
            'withdrawn': 2000,
            'processing_amount': 500,
          },
          'chart_points': <Map<String, dynamic>>[
            <String, dynamic>{'label': 'Mon', 'amount': 1200},
          ],
          'accounts': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'acct-1',
              'type': 'mobile_money',
              'name': 'Telebirr',
              'account_display': '+251 *** 1200',
              'verified': true,
            },
          ],
          'min_withdrawal': 500,
          'max_withdrawal': 20000,
          'earnings': <String, dynamic>{
            'count': 1,
            'next': null,
            'previous': null,
            'results': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'earn-1',
                'created_at': '2026-06-24T08:30:00Z',
                'order_id': 'ORD-1',
                'customer_name': 'Customer One',
                'commission_amount': 25,
                'gross': 500,
                'fee': 15,
                'net_amount': 460,
                'status': 'available',
              },
            ],
          },
        },
      );

      expect(dashboard.summary.totalEarnings, 12000.50);
      expect(dashboard.summary.pendingEarnings, 1500);
      expect(dashboard.chart.single.label, 'Mon');
      expect(dashboard.payoutAccounts.single.isVerified, isTrue);
      expect(dashboard.history.total, 1);
      expect(dashboard.history.items.single.status, EarningStatus.available);
      expect(dashboard.history.items.single.sourceOrder, 'ORD-1');
    });
  });

  group('PaginatedPayouts', () {
    test('parses payout status lifecycle from data pagination format', () {
      final PaginatedPayouts payouts = PaginatedPayouts.fromJson(
        <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'pay-1',
              'request_date': '2026-06-20T10:00:00Z',
              'amount': 1000,
              'fees': 20,
              'net_amount': 980,
              'method': 'Bank Transfer',
              'status': 'processing',
              'reference': 'BNK-1',
              'processed_at': null,
            },
          ],
          'pagination': <String, dynamic>{
            'page': 1,
            'page_size': 20,
            'total': 1,
            'has_more': false,
          },
        },
      );

      expect(payouts.items.single.status, PayoutStatus.processing);
      expect(payouts.items.single.transactionReference, 'BNK-1');
      expect(payouts.hasMore, isFalse);
    });
  });
}
