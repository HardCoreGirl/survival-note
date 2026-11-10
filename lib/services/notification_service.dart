import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/inspection_check.dart';
import '../models/item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int monthlyDigestNotificationId = 1001;
  static const int periodicInspectionNotificationId = 1002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_initialized || !_isMobilePlatform) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init skipped: $e');
    }
  }

  /// Anti-Fatigue Monthly Rolling Stock Digest:
  /// Avoids per-item notification spam. Groups all items expiring within 30~60 days
  /// into a SINGLE scheduled alert on the 1st day of the upcoming month at 10:00 AM.
  Future<void> syncMonthlyRollingStockDigest({
    required List<Item> allItems,
    required bool isKorean,
  }) async {
    if (!_initialized) return;

    final now = DateTime.now();
    // Calculate next 1st of the month at 10:00 AM local time
    final nextFirstOfMonth = (now.day == 1 && now.hour < 10)
        ? DateTime(now.year, now.month, 1, 10, 0)
        : DateTime(now.year, now.month + 1, 1, 10, 0);

    // Count items expiring within 60 days of the scheduled digest date
    final expiringItems = allItems
        .where((item) => item.isExpiringWithinDays(nextFirstOfMonth, 60))
        .toList();

    if (expiringItems.isEmpty) {
      await _plugin.cancel(monthlyDigestNotificationId);
      return;
    }

    final count = expiringItems.length;
    final title = isKorean
        ? '[생존 알림] 월간 비축품 교체 점검'
        : '[Survival Alert] Monthly Rolling Stock Check';
    final body = isKorean
        ? '[생존 알림] 이번 달 교체가 필요한 품목이 $count개 있습니다. 유통기한 전에 소비하세요!'
        : '[Survival Alert] $count items need replacement this month. Consume them before expiration!';

    final scheduledTz = tz.TZDateTime.from(nextFirstOfMonth, tz.local);

    await _plugin.zonedSchedule(
      monthlyDigestNotificationId,
      title,
      body,
      scheduledTz,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_rolling_stock_channel',
          'Monthly Rolling Stock Digest',
          channelDescription:
              'Single monthly digest on the 1st at 10:00 AM for expiring survival supplies.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Schedules the 6-Month Periodic Inspection reminder (battery leakage, power bank, seasonal gear)
  Future<void> syncPeriodicInspectionNotification({
    required InspectionCheck check,
    required bool isKorean,
  }) async {
    if (!_initialized) return;

    final nextDate = check.nextInspectionDate;
    final targetDateTime = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      10,
      0,
    );

    if (targetDateTime.isBefore(DateTime.now())) {
      return;
    }

    final title = isKorean
        ? '[생존 알림] 6개월 정기 장비 점검일'
        : '[Survival Alert] 6-Month Gear Inspection Due';
    final body = isKorean
        ? '건전지 누액, 보조배터리 충전 상태, 계절별 생존 장비를 점검할 시간입니다.'
        : 'Time to inspect battery leakage, power bank charge, and seasonal survival gear.';

    await _plugin.zonedSchedule(
      periodicInspectionNotificationId,
      title,
      body,
      tz.TZDateTime.from(targetDateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'periodic_inspection_channel',
          '6-Month Periodic Gear Inspection',
          channelDescription:
              'Semi-annual reminder to inspect batteries and seasonal gear.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
