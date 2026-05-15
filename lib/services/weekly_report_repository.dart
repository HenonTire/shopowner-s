import 'package:shop_manager/models/weekly_report.dart';

abstract class WeeklyReportRepository {
  Future<WeeklyReport> fetchWeeklyReport({
    DateTime? from,
    DateTime? to,
  });
}

class MockWeeklyReportRepository implements WeeklyReportRepository {
  const MockWeeklyReportRepository();

  @override
  Future<WeeklyReport> fetchWeeklyReport({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return WeeklyReport(
      generatedAt: DateTime.now(),
      growthRate: 0.084,
      points: const <WeeklyReportPoint>[
        WeeklyReportPoint(dayLabel: 'Mon', sales: 12340, orders: 28),
        WeeklyReportPoint(dayLabel: 'Tue', sales: 11020, orders: 25),
        WeeklyReportPoint(dayLabel: 'Wed', sales: 13210, orders: 30),
        WeeklyReportPoint(dayLabel: 'Thu', sales: 12540, orders: 31),
        WeeklyReportPoint(dayLabel: 'Fri', sales: 15960, orders: 37),
        WeeklyReportPoint(dayLabel: 'Sat', sales: 17220, orders: 42),
        WeeklyReportPoint(dayLabel: 'Sun', sales: 14180, orders: 33),
      ],
    );
  }
}

class BackendWeeklyReportRepository implements WeeklyReportRepository {
  const BackendWeeklyReportRepository();

  @override
  Future<WeeklyReport> fetchWeeklyReport({
    DateTime? from,
    DateTime? to,
  }) {
    throw UnimplementedError(
      'Connect BackendWeeklyReportRepository.fetchWeeklyReport to your API endpoint.',
    );
  }
}
