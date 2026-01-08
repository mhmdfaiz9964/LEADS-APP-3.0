import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app_badger/flutter_app_badger.dart';
import '../config/secrets.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService._internal();

  Future<void> updateBadgeCount(int count) async {
    bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
    if (isSupported) {
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        FlutterAppBadger.removeBadge();
      }
    }
  }

  Future<void> init() async {
    tz.initializeTimeZones();

    // 1. Initialise Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // 2. Request FCM Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // 3. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle Foreground Messages (FCM)
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   debugPrint('Got a message whilst in the foreground!');
    //   if (message.notification != null) {
    //     showImmediateNotification(
    //       id: message.hashCode,
    //       title: message.notification!.title ?? "New Update",
    //       body: message.notification!.body ?? "",
    //     );
    //   }
    // });

    // 5. Token Management
    _updateToken();

    // 6. Initialize OneSignal
    await _initOneSignal();
  }

  Future<void> _initOneSignal() async {
    // NOTE: Replace with your actual OneSignal App ID
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(Secrets.oneSignalAppId);

    // Request permission for push notifications
    OneSignal.Notifications.requestPermission(true);

    // Prompt user for external ID (link OneSignal ID with user email)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await OneSignal.login(user.email!);

      // Set user role tag (Admin/User) to target push notifications
      try {
        final role = await DatabaseService().getUserRole(user.uid);
        OneSignal.User.addTagWithKey('role', role);
        debugPrint("OneSignal Tag Set: role=$role");

        // Force Opt-In in case the SDK is in a 'soft' unsubscribe state
        OneSignal.User.pushSubscription.optIn();

        // Log subscription status for debugging
        final subscriptionId = OneSignal.User.pushSubscription.id;
        final isOptedIn = OneSignal.User.pushSubscription.optedIn;
        final token = OneSignal.User.pushSubscription.token;

        debugPrint("OneSignal Subscription ID: $subscriptionId");
        debugPrint("OneSignal Is Opted In: $isOptedIn");
        debugPrint(
          "OneSignal Push Token: ${token != null ? 'Exists' : 'NULL'}",
        );
      } catch (e) {
        debugPrint("Error setting OneSignal role tag: $e");
      }
    }
  }

  Future<void> _updateToken() async {
    try {
      String? token = await _messaging.getToken();
      final user = FirebaseAuth.instance.currentUser;
      if (token != null && user != null) {
        await DatabaseService().updateUserToken(user.uid, token);
      }
    } catch (e) {
      debugPrint("Error updating token: $e");
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Used for important alerts and push messages',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleReminderNotifications(
    String id,
    String title,
    DateTime scheduledTime,
  ) async {
    int notificationId = id.hashCode.abs();
    final triggers = [
      const Duration(hours: 12),
      const Duration(hours: 1),
      const Duration(minutes: 10),
      const Duration(minutes: 3), // Added 3 minutes before trigger
      Duration.zero, // At the time
    ];

    for (int i = 0; i < triggers.length; i++) {
      final triggerTime = scheduledTime.subtract(triggers[i]);
      if (triggerTime.isAfter(DateTime.now())) {
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId + i,
            'Reminder: $title',
            triggers[i] == Duration.zero
                ? 'Your task is due now!'
                : 'Due in ${triggers[i].inMinutes >= 60 ? "${triggers[i].inHours} hours" : "${triggers[i].inMinutes} minutes"}',
            tz.TZDateTime.from(triggerTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'reminders_channel',
                'Task Reminders',
                channelDescription: 'Notifications for lead tasks',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint("Scheduling error: $e");
        }
      }
    }
  }

  Future<void> cancelNotifications(String id) async {
    int notificationId = id.hashCode.abs();
    for (int i = 0; i < 5; i++) {
      await flutterLocalNotificationsPlugin.cancel(notificationId + i);
    }
  }

  /// Sends a push notification via OneSignal REST API.
  /// To use this, you need your OneSignal App ID and REST API Key.
  Future<void> scheduleOneSignalPush({
    required String title,
    required String message,
    required DateTime scheduledTime,
    required String creatorEmail,
  }) async {
    // Schedule push 3 minutes before the reminder
    final sendAt = scheduledTime.subtract(const Duration(minutes: 3));
    if (sendAt.isBefore(DateTime.now())) return;

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final appId = Secrets.oneSignalAppId;
    final restKey = Secrets.oneSignalRestKey;

    // Targets: The user who added the reminder and anyone with tag 'role': 'Admin'
    final body = jsonEncode({
      "app_id": appId,
      "headings": {"en": "Reminder Incoming!"},
      "contents": {"en": "$title: $message (Due in 3 mins)"},
      "send_after":
          sendAt
              .toUtc()
              .toIso8601String()
              .replaceAll('T', ' ')
              .substring(0, 19) +
          ' UTC',
      "include_external_user_ids": [creatorEmail],
      "filters": [
        {"field": "tag", "key": "role", "relation": "=", "value": "Admin"},
      ],
      "android_sound": "default", // Uses system default sound
      "ios_sound": "default",
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Basic $restKey",
        },
        body: body,
      );
      debugPrint("OneSignal Response: ${response.body}");
    } catch (e) {
      debugPrint("OneSignal Error: $e");
    }
  }

  /// Sends an immediate push notification for testing.
  Future<void> sendImmediatePush({
    required String title,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final appId = Secrets.oneSignalAppId;
    final restKey = Secrets.oneSignalRestKey;

    final body = jsonEncode({
      "app_id": appId,
      "headings": {"en": title},
      "contents": {"en": message},
      "include_external_user_ids": [user.email],
      "android_sound": "default",
      "ios_sound": "default",
    });

    try {
      // Ensure no whitespace
      final cleanKey = restKey.trim();

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Basic $cleanKey",
        },
        body: body,
      );

      debugPrint("OneSignal Response (Basic): ${response.statusCode}");

      // If Basic fails with 400/403, try Key style
      if (response.statusCode != 200) {
        debugPrint("Basic Auth failed. Retrying with 'Key' prefix...");
        response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Key $cleanKey",
          },
          body: body,
        );
        debugPrint("OneSignal Response (Key): ${response.statusCode}");
      }

      debugPrint("Final Body: ${response.body}");

      if (response.statusCode != 200) {
        throw "OneSignal API Error: ${response.statusCode} - ${response.body}";
      }

      final responseJson = jsonDecode(response.body);
      if (responseJson['errors'] != null) {
        throw "OneSignal Error: ${responseJson['errors']}";
      }
    } catch (e) {
      debugPrint("Immediate OneSignal Error: $e");
      rethrow; // Allow UI to handle and show error
    }
  }
}
