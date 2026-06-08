import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:domus/utils/db_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef TaskCompleteCallback =
    Future<void> Function(String taskId, bool complete);

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<NotificationResponse> streamController =
      StreamController.broadcast();

  static final Map<String, String> _taskIdMap = {};
  static TaskCompleteCallback? _onTaskComplete;

  static void registerOnTaskComplete(TaskCompleteCallback callback) {
    _onTaskComplete = callback;
  }

  @pragma('vm:entry-point')
  static Future<void> onTap(NotificationResponse notificationResponse) async {
    debugPrint('Notificacao: ${notificationResponse.actionId}');

    final payload = notificationResponse.payload;
    if (notificationResponse.actionId != 'concluir_tarefa') return;
    if (payload == null || !payload.startsWith('concluir|')) return;

    final parts = payload.split('|');
    if (parts.length < 2) return;

    final taskId = parts[1];
    if (_onTaskComplete != null) {
      await _onTaskComplete?.call(taskId, true);
    } else {
      await DbUtil.updateComplete(taskId, true);
    }
    await cancelTaskNotifications(taskId.hashCode);
    _taskIdMap.remove(taskId);
  }

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showScheduledRepeatingNotification({
    required String title,
    required String description,
    required DateTime taskTime,
    required String taskId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final firstMinutes =
        (prefs.getInt('first_notification') ?? 30).clamp(0, 10080).toInt();
    final repeatMinutes =
        (prefs.getInt('repeat_interval') ?? 20).clamp(1, 1440).toInt();

    tz.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    final notificationId = taskId.hashCode;
    await cancelTaskNotifications(notificationId);

    var notificationTime = tz.TZDateTime.from(
      taskTime,
      tz.local,
    ).subtract(Duration(minutes: firstMinutes));
    final dueTime = tz.TZDateTime.from(taskTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    while (notificationTime.isBefore(now)) {
      notificationTime = notificationTime.add(Duration(minutes: repeatMinutes));
    }

    if (notificationTime.isAfter(dueTime)) {
      debugPrint('Horario invalido para agendamento.');
      return;
    }

    _taskIdMap[taskId] = taskId;

    const androidDetails = AndroidNotificationDetails(
      'scheduled_repeating_channel',
      'Notificacoes repetitivas',
      channelDescription:
          'Notificacoes que se repetem ate a tarefa ser concluida',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'concluir_tarefa',
          'Concluir Tarefa',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const details = NotificationDetails(android: androidDetails);
    var index = 0;

    while (!notificationTime.isAfter(dueTime) && index < 64) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId + index,
        'Tarefa: $title',
        description.isEmpty ? 'Tarefa perto do horario' : description,
        notificationTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'concluir|$taskId',
      );

      index++;
      notificationTime = notificationTime.add(Duration(minutes: repeatMinutes));
    }
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const android = AndroidNotificationDetails(
      'firebase_notification',
      'Firebase Notifications',
      channelDescription: 'Notificacoes instantaneas do Firebase',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: android);
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  static Future<void> showBillDueNotification({
    required int id,
    required String title,
    required double value,
    required DateTime dueDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final firstDays =
        (prefs.getInt('bill_first_notification_days') ?? 5)
            .clamp(0, 365)
            .toInt();
    final repeatDays =
        (prefs.getInt('bill_repeat_interval_days') ?? 1)
            .clamp(1, 365)
            .toInt();

    tz.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    final firstNotificationTime = tz.TZDateTime.from(
      dueDate,
      tz.local,
    ).subtract(Duration(days: firstDays));

    const androidDetails = AndroidNotificationDetails(
      'bill_due_channel',
      'Contas a vencer',
      channelDescription: 'Avisos antes do vencimento das contas',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    final due = tz.TZDateTime.from(dueDate, tz.local);
    var notificationTime = firstNotificationTime;
    var index = 0;

    while (!notificationTime.isAfter(due)) {
      if (notificationTime.isAfter(now)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + index,
          'Conta a vencer: $title',
          'Valor R\$${value.toStringAsFixed(2)}',
          notificationTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'bill|$id',
        );
      }

      index++;
      notificationTime = notificationTime.add(Duration(days: repeatDays));
    }
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Notificacao $id cancelada');
  }

  static Future<void> cancelTaskNotifications(int id) async {
    for (var index = 0; index < 64; index++) {
      await flutterLocalNotificationsPlugin.cancel(id + index);
    }
    debugPrint('Notificacoes da tarefa $id canceladas');
  }

  static Future<void> cancelBillDueNotifications(int id) async {
    for (var index = 0; index <= 365; index++) {
      await flutterLocalNotificationsPlugin.cancel(id + index);
    }
    debugPrint('Notificacoes da conta $id canceladas');
  }
}
