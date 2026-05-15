import 'package:shop_manager/models/marketer_models.dart';

abstract class MarketerRepository {
  Future<MarketerOverviewData> fetchOverview();
  Future<List<MarketerChatMessage>> fetchMessages({required String marketerId});
  Future<void> sendMessage({required String marketerId, required String text});
  Future<void> createContract(CreateMarketerContractRequest request);
}

class MockMarketerRepository implements MarketerRepository {
  const MockMarketerRepository();

  static const List<MarketerSummary> _allMarketers = <MarketerSummary>[
    MarketerSummary(
      id: 'alem-genet',
      name: 'Alem Genet',
      specialization: 'Facebook Ads Expert',
      tagline: 'Performance campaigns with weekly ROI reporting.',
      rating: 4.9,
      totalOrders: 842,
      conversionRate: 5.6,
      revenueGenerated: 'ETB 120,000',
      badgeLabel: 'Top Performer',
      avatarColorHex: '#1E88E5',
    ),
    MarketerSummary(
      id: 'samuel-taye',
      name: 'Samuel Taye',
      specialization: 'TikTok Growth Strategist',
      tagline: 'Fast testing cycles focused on profitable audiences.',
      rating: 4.8,
      totalOrders: 730,
      conversionRate: 5.2,
      revenueGenerated: 'ETB 104,500',
      badgeLabel: 'Top Performer',
      avatarColorHex: '#43A047',
    ),
    MarketerSummary(
      id: 'mimi-haile',
      name: 'Mimi Haile',
      specialization: 'Content Creator',
      tagline: 'Creative-first video funnels that convert to sales.',
      rating: 4.7,
      totalOrders: 668,
      conversionRate: 4.9,
      revenueGenerated: 'ETB 96,200',
      badgeLabel: 'Top Performer',
      avatarColorHex: '#F4511E',
    ),
    MarketerSummary(
      id: 'nati-birhanu',
      name: 'Nati Birhanu',
      specialization: 'Google Ads Specialist',
      tagline: 'High-intent search strategy for ready-to-buy shoppers.',
      rating: 4.2,
      totalOrders: 391,
      conversionRate: 3.1,
      revenueGenerated: 'ETB 54,900',
      badgeLabel: 'Growing',
      avatarColorHex: '#8E24AA',
    ),
    MarketerSummary(
      id: 'ruth-solomon',
      name: 'Ruth Solomon',
      specialization: 'Email & Retention Marketer',
      tagline: 'Recover abandoned carts and increase repeat purchases.',
      rating: 3.9,
      totalOrders: 250,
      conversionRate: 2.4,
      revenueGenerated: 'ETB 33,200',
      badgeLabel: 'Needs Review',
      avatarColorHex: '#6D4C41',
    ),
  ];

  static final List<MarketerChatThread> _threads = <MarketerChatThread>[
    MarketerChatThread(
      marketer: _allMarketers[0],
      lastMessage: 'I have shared this week\'s ad set performance report.',
      sentAt: '09:45',
      unreadCount: 2,
      online: true,
    ),
    MarketerChatThread(
      marketer: _allMarketers[1],
      lastMessage: 'Let us test two creatives before we scale budget.',
      sentAt: '08:12',
      unreadCount: 1,
      online: true,
    ),
    MarketerChatThread(
      marketer: _allMarketers[2],
      lastMessage: 'Can you review tomorrow\'s posting schedule?',
      sentAt: 'Yesterday',
      unreadCount: 0,
      online: false,
    ),
    MarketerChatThread(
      marketer: _allMarketers[3],
      lastMessage: 'Search campaign CPC dropped by 11% this week.',
      sentAt: 'Yesterday',
      unreadCount: 0,
      online: false,
    ),
  ];

  static final List<ActiveMarketerContract> _activeContracts = <ActiveMarketerContract>[
    ActiveMarketerContract(
      id: 'contract-alem-2026-q2',
      marketerId: 'alem-genet',
      name: 'Alem Genet',
      specialization: 'Facebook Ads Expert',
      contractStatus: 'Active',
      startDate: DateTime(2026, 4, 10),
      endDate: DateTime(2026, 6, 8),
      campaignProgress: 0.74,
      budgetUsed: 51200,
      budgetTotal: 70000,
      revenue: 154300,
      orders: 911,
      conversionRate: 5.8,
      trendPercent: 7.4,
      avatarColorHex: '#1E88E5',
    ),
    ActiveMarketerContract(
      id: 'contract-samuel-2026-q2',
      marketerId: 'samuel-taye',
      name: 'Samuel Taye',
      specialization: 'TikTok Growth Strategist',
      contractStatus: 'Expiring Soon',
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 5, 10),
      campaignProgress: 0.89,
      budgetUsed: 87500,
      budgetTotal: 92000,
      revenue: 131600,
      orders: 754,
      conversionRate: 3.1,
      trendPercent: -3.6,
      avatarColorHex: '#43A047',
    ),
    ActiveMarketerContract(
      id: 'contract-mimi-2026-q2',
      marketerId: 'mimi-haile',
      name: 'Mimi Haile',
      specialization: 'Content Creator',
      contractStatus: 'Pending',
      startDate: DateTime(2026, 5, 6),
      endDate: DateTime(2026, 7, 5),
      campaignProgress: 0.22,
      budgetUsed: 13800,
      budgetTotal: 64000,
      revenue: 22600,
      orders: 128,
      conversionRate: 2.3,
      trendPercent: -1.8,
      avatarColorHex: '#F4511E',
    ),
  ];

  static final List<PastMarketerContract> _pastContracts = <PastMarketerContract>[
    PastMarketerContract(
      id: 'contract-nati-2025-q4',
      marketerId: 'nati-birhanu',
      name: 'Nati Birhanu',
      specialization: 'Google Ads Specialist',
      finalStatus: 'Completed',
      totalRevenue: 187400,
      totalOrders: 1092,
      finalConversionRate: 4.4,
      spent: 92000,
      rating: 4,
      review: 'Strong at high-intent traffic and consistent reporting.',
      avatarColorHex: '#8E24AA',
    ),
    PastMarketerContract(
      id: 'contract-ruth-2025-q4',
      marketerId: 'ruth-solomon',
      name: 'Ruth Solomon',
      specialization: 'Email & Retention Marketer',
      finalStatus: 'Completed',
      totalRevenue: 68400,
      totalOrders: 351,
      finalConversionRate: 2.6,
      spent: 54000,
      rating: 3,
      review: 'Decent recovery campaigns, but growth flattened later.',
      avatarColorHex: '#6D4C41',
    ),
    PastMarketerContract(
      id: 'contract-dawit-2025-q3',
      marketerId: 'dawit-mamo',
      name: 'Dawit Mamo',
      specialization: 'Marketplace Promotions Lead',
      finalStatus: 'Cancelled',
      totalRevenue: 30100,
      totalOrders: 184,
      finalConversionRate: 1.7,
      spent: 46000,
      rating: 2,
      review: 'Paused due to weak conversion and channel mismatch.',
      avatarColorHex: '#00897B',
    ),
  ];

  static final Map<String, List<MarketerChatMessage>> _messagesByMarketer =
      <String, List<MarketerChatMessage>>{
    'alem-genet': <MarketerChatMessage>[
      MarketerChatMessage(
        id: 'msg-1',
        marketerId: 'alem-genet',
        text:
            'Hi, I reviewed your shop and I can help improve conversion with better campaign structure.',
        fromMarketer: true,
        sentAt: '09:18',
      ),
      MarketerChatMessage(
        id: 'msg-2',
        marketerId: 'alem-genet',
        text:
            'Great, I want to hire you on contract. Let us align on weekly goals and budget pacing.',
        fromMarketer: false,
        sentAt: '09:20',
      ),
    ],
  };

  @override
  Future<MarketerOverviewData> fetchOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return MarketerOverviewData(
      topPerformers: <MarketerSummary>[
        _allMarketers[0],
        _allMarketers[1],
        _allMarketers[2],
      ],
      allMarketers: _allMarketers,
      chatThreads: _threads,
      activeContracts: _activeContracts,
      pastContracts: _pastContracts,
    );
  }

  @override
  Future<List<MarketerChatMessage>> fetchMessages({required String marketerId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 380));
    return List<MarketerChatMessage>.from(
      _messagesByMarketer[marketerId] ??
          <MarketerChatMessage>[
            MarketerChatMessage(
              id: 'seed-$marketerId-1',
              marketerId: marketerId,
              text: 'Hello, I am ready to discuss your campaign goals.',
              fromMarketer: true,
              sentAt: '08:45',
            ),
          ],
      growable: false,
    );
  }

  @override
  Future<void> sendMessage({required String marketerId, required String text}) async {
    await Future<void>.delayed(const Duration(milliseconds: 230));
    final List<MarketerChatMessage> current =
        _messagesByMarketer.putIfAbsent(marketerId, () => <MarketerChatMessage>[]);
    current.add(
      MarketerChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        marketerId: marketerId,
        text: text,
        fromMarketer: false,
        sentAt: _nowLabel(),
      ),
    );
  }

  @override
  Future<void> createContract(CreateMarketerContractRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  String _nowLabel() {
    final DateTime now = DateTime.now();
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class BackendMarketerRepository implements MarketerRepository {
  const BackendMarketerRepository();

  @override
  Future<MarketerOverviewData> fetchOverview() {
    throw UnimplementedError(
      'Connect BackendMarketerRepository.fetchOverview to your API endpoint.',
    );
  }

  @override
  Future<List<MarketerChatMessage>> fetchMessages({required String marketerId}) {
    throw UnimplementedError(
      'Connect BackendMarketerRepository.fetchMessages to your API endpoint.',
    );
  }

  @override
  Future<void> sendMessage({required String marketerId, required String text}) {
    throw UnimplementedError(
      'Connect BackendMarketerRepository.sendMessage to your API endpoint.',
    );
  }

  @override
  Future<void> createContract(CreateMarketerContractRequest request) {
    throw UnimplementedError(
      'Connect BackendMarketerRepository.createContract to your API endpoint.',
    );
  }
}
