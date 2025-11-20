// TODO: Implementar notificaciones más adelante
// Archivo completo comentado para implementación futura

/*
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/notification.dart';

class NotificationService {
  static const String _tag = 'NotificationService';
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers para notificaciones
  static final StreamController<AppNotification> _notificationStreamController = 
      StreamController<AppNotification>.broadcast();
  static final StreamController<List<AppNotification>> _notificationListStreamController = 
      StreamController<List<AppNotification>>.broadcast();
  
  // Streams públicos
  static Stream<AppNotification> get notificationStream => _notificationStreamController.stream;
  static Stream<List<AppNotification>> get notificationListStream => _notificationListStreamController.stream;
  
  // Cache de notificaciones
  static List<AppNotification> _cachedNotifications = [];
  static bool _isInitialized = false;
  
  // Listeners para cambios de estado
  static StreamSubscription<QuerySnapshot>? _accountsListener;
  static StreamSubscription<QuerySnapshot>? _cardsListener;

  /// Inicializa el servicio de notificaciones
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('$_tag: Inicializando servicio de notificaciones...');
      
      // Configurar notificaciones locales
      await _initializeLocalNotifications();
      
      // Configurar Firebase Messaging
      await _initializeFirebaseMessaging();
      
      // Cargar notificaciones existentes
      await _loadNotifications();
      
      // Configurar listeners para cambios de estado
      await _setupStateListeners();
      
      _isInitialized = true;
      print('$_tag: Servicio de notificaciones inicializado correctamente');
    } catch (e) {
      print('$_tag: Error al inicializar el servicio de notificaciones: $e');
      rethrow;
    }
  }

  /// Configura las notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    await _createNotificationChannel();
  }

  /// Crea el canal de notificaciones para Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'microfinance_notifications',
      'Microfinance Notifications',
      description: 'Notificaciones de la aplicación de microfinanzas',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configura Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('$_tag: Permisos de notificación concedidos');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('$_tag: Permisos de notificación provisionales concedidos');
    } else {
      print('$_tag: Permisos de notificación denegados');
    }

    // Obtener token FCM
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('$_tag: Token FCM: $token');
      await _saveTokenToFirestore(token);
    }

    // Configurar handlers para mensajes
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Manejar mensaje que abrió la app (cuando estaba cerrada)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessageOpenedApp(initialMessage);
    }

    // Listener para cambios de token
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  /// Maneja mensajes en primer plano
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('$_tag: Mensaje en primer plano: ${message.messageId}');
    
    // Mostrar notificación local
    await _showLocalNotification(message);
    
    // Guardar en Firestore
    await _saveNotificationToFirestore(message);
  }

  /// Maneja mensajes cuando la app se abre desde una notificación
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('$_tag: App abierta desde notificación: ${message.messageId}');
    
    // Procesar acción de la notificación
    await _processNotificationAction(message);
  }

  /// Muestra una notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'microfinance_notifications',
        'Microfinance Notifications',
        channelDescription: 'Notificaciones de la aplicación de microfinanzas',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Nueva notificación',
        message.notification?.body ?? '',
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('$_tag: Error al mostrar notificación local: $e');
    }
  }

  /// Guarda la notificación en Firestore
  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Nueva notificación',
        message: message.notification?.body ?? '',
        type: _parseNotificationType(message.data['type']),
        priority: _parseNotificationPriority(message.data['priority']),
        userId: user.uid,
        data: message.data,
        createdAt: DateTime.now(),
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Actualizar cache local
      _cachedNotifications.insert(0, notification);
      _notificationStreamController.add(notification);
      _notificationListStreamController.add(List.from(_cachedNotifications));

      print('$_tag: Notificación guardada en Firestore: ${notification.id}');
    } catch (e) {
      print('$_tag: Error al guardar notificación en Firestore: $e');
    }
  }

  /// Carga las notificaciones existentes desde Firestore
  static Future<void> _loadNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _cachedNotifications = querySnapshot.docs
          .map((doc) => AppNotification.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _notificationListStreamController.add(List.from(_cachedNotifications));
      print('$_tag: ${_cachedNotifications.length} notificaciones cargadas');
    } catch (e) {
      print('$_tag: Error al cargar notificaciones: $e');
    }
  }

  /// Guarda el token FCM en Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('$_tag: Token FCM guardado en Firestore');
    } catch (e) {
      print('$_tag: Error al guardar token FCM: $e');
    }
  }

  /// Configura listeners para cambios de estado
  static Future<void> _setupStateListeners() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Listener para cambios en cuentas
      _accountsListener = _firestore
          .collection('accounts')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final data = change.doc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            
            if (status == 'active') {
              _sendAccountActivationNotification(
                accountId: change.doc.id,
                accountType: data['accountType'] ?? 'Cuenta',
              );
            }
          }
        }
      });

      // Listener para cambios en tarjetas
      _cardsListener = _firestore
          .collection('cards')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final data = change.doc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            
            if (status == 'active') {
              _sendCardActivationNotification(
                cardId: change.doc.id,
                cardType: data['cardType'] ?? 'Tarjeta',
                lastFourDigits: data['cardNumber']?.toString().substring(
                  data['cardNumber'].toString().length - 4
                ) ?? '****',
              );
            }
          }
        }
      });

      print('$_tag: Listeners de estado configurados');
    } catch (e) {
      print('$_tag: Error al configurar listeners de estado: $e');
    }
  }

  /// Envía notificación de activación de cuenta
  static Future<void> _sendAccountActivationNotification({
    required String accountId,
    required String accountType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await sendNotification(
        userId: user.uid,
        title: '¡Cuenta Activada!',
        message: 'Tu $accountType ha sido activada exitosamente',
        type: NotificationType.accountActivated,
        priority: NotificationPriority.high,
        data: {
          'accountId': accountId,
          'accountType': accountType,
          'action': 'view_account',
        },
      );

      print('$_tag: Notificación de activación de cuenta enviada');
    } catch (e) {
      print('$_tag: Error al enviar notificación de activación de cuenta: $e');
    }
  }

  /// Envía notificación de activación de tarjeta
  static Future<void> _sendCardActivationNotification({
    required String cardId,
    required String cardType,
    required String lastFourDigits,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await sendNotification(
        userId: user.uid,
        title: '¡Tarjeta Activada!',
        message: 'Tu $cardType terminada en $lastFourDigits está lista para usar',
        type: NotificationType.cardActivated,
        priority: NotificationPriority.high,
        data: {
          'cardId': cardId,
          'cardType': cardType,
          'lastFourDigits': lastFourDigits,
          'action': 'view_card',
        },
      );

      print('$_tag: Notificación de activación de tarjeta enviada');
    } catch (e) {
      print('$_tag: Error al enviar notificación de activación de tarjeta: $e');
    }
  }

  /// Procesa la acción de una notificación
  static Future<void> _processNotificationAction(RemoteMessage message) async {
    try {
      final action = message.data['action'] as String?;
      final data = message.data;

      switch (action) {
        case 'view_account':
          // Navegar a la pantalla de cuenta
          print('$_tag: Navegando a cuenta: ${data['accountId']}');
          break;
        case 'view_card':
          // Navegar a la pantalla de tarjeta
          print('$_tag: Navegando a tarjeta: ${data['cardId']}');
          break;
        default:
          print('$_tag: Acción no reconocida: $action');
      }
    } catch (e) {
      print('$_tag: Error al procesar acción de notificación: $e');
    }
  }

  /// Maneja el tap en una notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final action = data['action'] as String?;

        switch (action) {
          case 'view_account':
            print('$_tag: Navegando a cuenta desde notificación local');
            break;
          case 'view_card':
            print('$_tag: Navegando a tarjeta desde notificación local');
            break;
        }
      }
    } catch (e) {
      print('$_tag: Error al manejar tap en notificación: $e');
    }
  }

  /// Envía una notificación personalizada
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        priority: priority,
        userId: userId,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        createdAt: DateTime.now(),
      );

      // Guardar en Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Actualizar cache local si es para el usuario actual
      final currentUser = _auth.currentUser;
      if (currentUser?.uid == userId) {
        _cachedNotifications.insert(0, notification);
        _notificationStreamController.add(notification);
        _notificationListStreamController.add(List.from(_cachedNotifications));

        // Mostrar notificación local
        await _showLocalNotificationFromData(notification);
      }

      print('$_tag: Notificación enviada: ${notification.id}');
    } catch (e) {
      print('$_tag: Error al enviar notificación: $e');
      rethrow;
    }
  }

  /// Muestra una notificación local desde datos de AppNotification
  static Future<void> _showLocalNotificationFromData(AppNotification notification) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'microfinance_notifications',
        'Microfinance Notifications',
        channelDescription: 'Notificaciones de la aplicación de microfinanzas',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.message,
        platformChannelSpecifics,
        payload: jsonEncode(notification.data ?? {}),
      );
    } catch (e) {
      print('$_tag: Error al mostrar notificación local desde datos: $e');
    }
  }

  /// Marca una notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Actualizar cache local
      final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cachedNotifications[index] = _cachedNotifications[index].copyWith(isRead: true);
        _notificationListStreamController.add(List.from(_cachedNotifications));
      }

      print('$_tag: Notificación marcada como leída: $notificationId');
    } catch (e) {
      print('$_tag: Error al marcar notificación como leída: $e');
    }
  }

  /// Marca todas las notificaciones como leídas
  static Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = _cachedNotifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        batch.update(
          _firestore.collection('users').doc(user.uid).collection('notifications').doc(notification.id),
          {'isRead': true},
        );
      }

      await batch.commit();

      // Actualizar cache local
      _cachedNotifications = _cachedNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _notificationListStreamController.add(List.from(_cachedNotifications));

      print('$_tag: Todas las notificaciones marcadas como leídas');
    } catch (e) {
      print('$_tag: Error al marcar todas las notificaciones como leídas: $e');
    }
  }

  /// Obtiene el número de notificaciones no leídas
  static int getUnreadCount() {
    return _cachedNotifications.where((n) => !n.isRead).length;
  }

  /// Obtiene todas las notificaciones
  static List<AppNotification> get notifications => List.from(_cachedNotifications);

  /// Elimina una notificación
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      _cachedNotifications.removeWhere((n) => n.id == notificationId);
      _notificationListStreamController.add(List.from(_cachedNotifications));

      print('$_tag: Notificación eliminada: $notificationId');
    } catch (e) {
      print('$_tag: Error al eliminar notificación: $e');
    }
  }

  /// Limpia todas las notificaciones
  static Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();

      for (final notification in _cachedNotifications) {
        batch.delete(
          _firestore.collection('users').doc(user.uid).collection('notifications').doc(notification.id),
        );
      }

      await batch.commit();
      _cachedNotifications.clear();
      _notificationListStreamController.add([]);

      print('$_tag: Todas las notificaciones eliminadas');
    } catch (e) {
      print('$_tag: Error al eliminar todas las notificaciones: $e');
    }
  }

  /// Parsea el tipo de notificación desde string
  static NotificationType _parseNotificationType(dynamic value) {
    if (value == null) return NotificationType.general;
    
    switch (value.toString().toLowerCase()) {
      case 'account_activated':
        return NotificationType.accountActivated;
      case 'card_activated':
        return NotificationType.cardActivated;
      case 'loan_approved':
        return NotificationType.loanApproved;
      case 'loan_rejected':
        return NotificationType.loanRejected;
      case 'payment_reminder':
        return NotificationType.paymentReminder;
      default:
        return NotificationType.general;
    }
  }

  /// Parsea la prioridad de notificación desde string
  static NotificationPriority _parseNotificationPriority(dynamic value) {
    if (value == null) return NotificationPriority.normal;
    
    switch (value.toString().toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Limpia recursos y cierra streams
  static Future<void> dispose() async {
    try {
      await _accountsListener?.cancel();
      await _cardsListener?.cancel();
      await _notificationStreamController.close();
      await _notificationListStreamController.close();
      
      _isInitialized = false;
      print('$_tag: Servicio de notificaciones limpiado');
    } catch (e) {
      print('$_tag: Error al limpiar servicio de notificaciones: $e');
    }
  }
}

/// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('NotificationService: Mensaje en segundo plano: ${message.messageId}');
}
*/