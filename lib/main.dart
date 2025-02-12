import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// This needs to be outside of main() as it needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handlers
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  if (message.notification != null) {
    print("Message notification: ${message.notification}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up FCM
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get FCM token and print it (for debugging)
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Configure FCM callbacks for different states
  // When the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    }
  });

  // When the app is in the background and user taps on the notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    }
  });

  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Get any initial message that launched the app
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('App launched via notification!');
    print('Message data: ${initialMessage.data}');

    if (initialMessage.notification != null) {
      print('Message also contained a notification:');
      print('Title: ${initialMessage.notification?.title}');
      print('Body: ${initialMessage.notification?.body}');
    }
  }

  // Subscribe to topics (optional)
  await messaging.subscribeToTopic('all_users');
  print('Subscribed to all_users topic');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
