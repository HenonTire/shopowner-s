import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/marketer_models.dart';
import 'package:shop_manager/services/marketer_repository.dart';

final marketerRepositoryProvider = Provider<MarketerRepository>(
  (ProviderRef<MarketerRepository> ref) {
    return  BackendMarketerRepository();
  },
);

final marketerOverviewProvider = FutureProvider<MarketerOverviewData>(
  (FutureProviderRef<MarketerOverviewData> ref) async {
    final MarketerRepository repository = ref.watch(marketerRepositoryProvider);
    return repository.fetchOverview();
  },
);

final marketerChatMessagesProvider =
    FutureProvider.family<List<MarketerChatMessage>, String>(
  (FutureProviderRef<List<MarketerChatMessage>> ref, String marketerId) async {
    final MarketerRepository repository = ref.watch(marketerRepositoryProvider);
    return repository.fetchMessages(marketerId: marketerId);
  },
);
