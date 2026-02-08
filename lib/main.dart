import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/event_service.dart';
import 'services/notification_service.dart';
import 'services/program_service.dart';
import 'services/group_service.dart';
import 'services/assistant_service.dart';
import 'services/user_service.dart';
import 'services/transaction_service.dart';
import 'services/payment_service.dart';
import 'widgets/app_overlay.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/app_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'widgets/notification_overlay.dart';
import 'models/user_model.dart'; // for UserRole

// Background FCM handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications setup
  final FlutterLocalNotificationsPlugin localNotifs =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  // Correct call – uses required named parameter 'settings'
  await localNotifs.initialize(settings: initSettings);

  runApp(const RCTConnectApp());
}

class RCTConnectApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  const RCTConnectApp({super.key});

  @override
  State<RCTConnectApp> createState() => _RCTConnectAppState();
}

class _RCTConnectAppState extends State<RCTConnectApp> {
  // Theme is now managed by ThemeService

  @override
  @override
  Widget build(BuildContext context) {
    // Explicitly define base text theme with sizes to prevent "fontSize != null" assertion failure during scaling
    final baseTextTheme = ThemeData.light().textTheme.copyWith(
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 14),
          bodySmall: const TextStyle(fontSize: 12),
          headlineLarge: const TextStyle(fontSize: 32),
          headlineMedium: const TextStyle(fontSize: 28),
          headlineSmall: const TextStyle(fontSize: 24),
          titleLarge: const TextStyle(fontSize: 22),
          titleMedium: const TextStyle(fontSize: 16),
          titleSmall: const TextStyle(fontSize: 14),
          displayLarge: const TextStyle(fontSize: 57),
          displayMedium: const TextStyle(fontSize: 45),
          displaySmall: const TextStyle(fontSize: 36),
          labelLarge: const TextStyle(fontSize: 14),
          labelMedium: const TextStyle(fontSize: 12),
          labelSmall: const TextStyle(fontSize: 11),
        );
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(
            create: (_) => NotificationService()..initialize()),
        ChangeNotifierProvider(create: (_) => ProgramService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
        ChangeNotifierProxyProvider<TransactionService, PaymentService>(
          create: (context) => PaymentService(
              Provider.of<TransactionService>(context, listen: false)),
          update: (context, transactionService, previous) =>
              PaymentService(transactionService),
        ),
        ChangeNotifierProvider(
            create: (_) => AssistantService(RCTConnectApp.navigatorKey)),
      ],
      child: Consumer2<AuthService, ThemeService>(
        builder: (context, auth, themeService, child) {
          return MaterialApp(
            navigatorKey: RCTConnectApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'RCT Connect',
            theme: AppTheme.light(
                textTheme, themeService.currentColors, themeService.fontScale),
            darkTheme: AppTheme.dark(
                textTheme, themeService.currentColors, themeService.fontScale),
            themeMode: themeService.themeMode,
            home: AppOverlay(
              child: NotificationOverlayListener(
                child: Builder(
                  builder: (context) {
                    // Helper to toggle theme using service
                    void onToggleTheme() => themeService.toggleTheme();

                    if (auth.isLoading) {
                      return const Scaffold(
                          body: Center(child: CircularProgressIndicator()));
                    }

                    final user = auth.currentUser;

                    if (user == null) {
                      return SplashScreen(
                        onGetStarted: () async {
                          await auth.login('visitor', '');
                        },
                        onLogin: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoginScreen(onToggleTheme: onToggleTheme),
                            ),
                          );
                        },
                      );
                    }

                    if (user.role == UserRole.visitor) {
                      return AppShell(
                          onToggleTheme: onToggleTheme, isGuest: true);
                    }

                    return user.role == UserRole.adminPrincipal ||
                            user.role == UserRole.adminCoach ||
                            user.role == UserRole.groupAdmin
                        ? AdminShell(
                            onToggleTheme: onToggleTheme,
                            currentUser: user,
                            isCoach: user.role == UserRole.adminCoach,
                            isGroupAdmin: user.role == UserRole.groupAdmin,
                          )
                        : AppShell(
                            onToggleTheme: onToggleTheme,
                            forceTutorial: auth.justRegistered,
                          );
                  },
                ),
              ),
            ),
            routes: {
              '/signup': (_) => SignUpScreen(
                    onToggleTheme: () =>
                        Provider.of<ThemeService>(context, listen: false)
                            .toggleTheme(),
                  ),
            },
          );
        },
      ),
    );
  }
}
