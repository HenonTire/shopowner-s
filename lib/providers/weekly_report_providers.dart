import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/weekly_report.dart';
import 'package:shop_manager/services/weekly_report_repository.dart';

final weeklyReportRepositoryProvider = Provider<WeeklyReportRepository>(
  (ProviderRef<WeeklyReportRepository> ref) {
    return const MockWeeklyReportRepository();
  },
);

final weeklyReportProvider = FutureProvider<WeeklyReport>(
  (FutureProviderRef<WeeklyReport> ref) async {
    final WeeklyReportRepository repository =
        ref.watch(weeklyReportRepositoryProvider);
    return repository.fetchWeeklyReport();
  },
);
