import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../screens/order_list_screen.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  String? _activeUserId;
  String? _activeToken;
  bool _isStarting = false;
  ValueChanged<int>? _onNavigateTab;
  ValueChanged<String>? _onSelectCategory;

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void setDashboardNavigation({
    required ValueChanged<int> onNavigateTab,
    required ValueChanged<String> onSelectCategory,
  }) {
    _onNavigateTab = onNavigateTab;
    _onSelectCategory = onSelectCategory;
  }

  void clearDashboardNavigation() {
    _onNavigateTab = null;
    _onSelectCategory = null;
  }

  Future<void> start() async {
    if (!_supportsPush ||
        Firebase.apps.isEmpty ||
        _isStarting ||
        _messageSubscription != null) {
      return;
    }

    _isStarting = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
        onError: (Object error) {
          debugPrint('Unable to receive foreground notifications: $error');
        },
      );
      _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openFromNotification,
        onError: (Object error) {
          debugPrint('Unable to handle opened push notification: $error');
        },
      );
      _tokenSubscription = messaging.onTokenRefresh.listen(
        (token) {
          final userId = _activeUserId;
          if (userId != null) unawaited(_saveToken(userId, token));
        },
        onError: (Object error) {
          debugPrint('Unable to refresh the push notification token: $error');
        },
      );
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (user) => unawaited(_registerForUser(user)),
        onError: (Object error) {
          debugPrint(
            'Unable to observe push notification sign-in state: $error',
          );
        },
      );
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _openFromNotification(initialMessage);
    } catch (error, stackTrace) {
      debugPrint('Unable to start push notifications: $error\n$stackTrace');
      await stop();
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stop() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _messageSubscription = null;
    _openedMessageSubscription = null;
  }

  Future<void> _registerForUser(User? user) async {
    final nextUserId = user?.uid;
    if (_activeUserId != nextUserId) {
      final previousUserId = _activeUserId;
      final previousToken = _activeToken;
      _activeUserId = nextUserId;
      _activeToken = null;
      if (previousUserId != null) {
        unawaited(_deletePreviousUserToken(previousUserId, previousToken));
      }
    }
    if (user == null) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || _activeUserId != user.uid) return;
      await _saveToken(user.uid, token);
    } catch (error, stackTrace) {
      debugPrint('Unable to register push notifications: $error\n$stackTrace');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    if (_activeUserId != userId) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (_activeUserId != userId) {
        await _deleteToken(userId, token);
        return;
      }

      final previousToken = _activeToken;
      _activeToken = token;
      if (previousToken != null && previousToken != token) {
        await _deleteToken(userId, previousToken);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to save the push notification token: $error\n$stackTrace',
      );
    }
  }

  Future<void> _deleteToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete();
    } catch (error) {
      debugPrint('Unable to remove a previous push notification token: $error');
    }
  }

  Future<void> _deletePreviousUserToken(
    String userId,
    String? knownToken,
  ) async {
    try {
      final token = knownToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) await _deleteToken(userId, token);
    } catch (error) {
      debugPrint("Unable to find the previous user's push token: $error");
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null || title is! String || title.isEmpty) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            body is String && body.isNotEmpty ? '$title\n$body' : title,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
  }

  void _openFromNotification(RemoteMessage message) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
        'Cannot open push destination before the app navigator loads.',
      );
      return;
    }

    if (message.data['type'] == 'order_status') {
      final onNavigateTab = _onNavigateTab;
      if (onNavigateTab != null) {
        navigator.popUntil((route) => route.isFirst);
        onNavigateTab(3);
      } else {
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const OrderListScreen()),
        );
      }
      return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          onNavigateTab: _onNavigateTab,
          onSelectCategory: _onSelectCategory,
        ),
      ),
    );
  }
}
