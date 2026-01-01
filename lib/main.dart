// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Pages/splash_screen.dart';
import 'package:threadhub_system/Tailor/pages/menu item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/firebase_options.dart';
import 'package:threadhub_system/Pages/theme_provider.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash until initialization
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: "https://lyoarnvbiegjplqbakyg.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5b2FybnZiaWVnanBscWJha3lnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyNzYxODYsImV4cCI6MjA3Mzg1MjE4Nn0.mJzp4HUoAkh_O3mc6DuTnkxkv6NQdU5pl6IYzYjJaYE",
  );

  // Initialize Local Notifications
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );
  await notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    },
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  final token = await messaging.getToken();
  // debugPrint('FCM Token: $token');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => TailorFontprovider()),
        // ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.notification?.title}');
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    });

    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    // final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      // theme: ThemeData(
      //   brightness: Brightness.light,
      //   scaffoldBackgroundColor: Colors.white,
      //   useMaterial3: true,
      // ),
      // darkTheme: ThemeData(
      //   brightness: Brightness.dark,
      //   scaffoldBackgroundColor: const Color(0xFF121212),
      //   colorScheme: const ColorScheme.dark(),
      //   useMaterial3: true,
      // ),

      home: const SplashScreen(),
    );
  }
}

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showLocalNotification(message);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel_id',
    'General Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  await notifications.show(
    message.notification.hashCode,
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? '',
    platformDetails,
  );
}
