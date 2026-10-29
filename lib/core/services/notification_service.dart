// lib/core/services/notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda bildirim geldiğinde çalışır
  debugPrint('Arka plan bildirimi alındı: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!kIsWeb) {
        // Android / iOS için google-services.json'dan otomatik okur
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        final messaging = FirebaseMessaging.instance;

        // Bildirim izni iste
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

      debugPrint('Bildirim izin durumu: ${settings.authorizationStatus}');

      _initialized = true;

      // Token'ı al ve kaydet
      await syncTokenWithSupabase();

      // Token yenilenirse Supabase'i güncelle
      messaging.onTokenRefresh.listen((newToken) {
        syncTokenWithSupabase(customToken: newToken);
      });

        // Uygulama açıkken gelen bildirimleri dinle
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Ön planda bildirim geldi: ${message.notification?.title}');
        });
      }
    } catch (e) {
      debugPrint('Firebase/FCM başlatma uyarısı (normal): $e');
    }
  }

  /// Kullanıcının fcm_token değerini Supabase users tablosuna yazar
  Future<void> syncTokenWithSupabase({String? customToken}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final token = customToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Token: $token');
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('FCM Token Supabase ile eşitlendi 🐾');
      }
    } catch (e) {
      debugPrint('FCM Token Supabase kayıt hatası: $e');
    }
  }
}
