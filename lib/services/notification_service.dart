import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  NotificationService() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notification',
          channelDescription: 'Notification channel for basic test',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
      debug: true, // Set to false in production
    );
  }

  void requestPermissionIfNeeded() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void showTestNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10, // Unique notification ID
        channelKey: 'basic_channel',
        title: 'Test Notification',
        body: 'This is a test notification triggered by NotificationService',
      ),
    );
  }
}
