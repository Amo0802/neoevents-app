import 'package:events_amo/pages/main_page.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/event_provider.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/services/api_client.dart';
import 'package:events_amo/services/auth_service.dart';
import 'package:events_amo/services/event_service.dart';
import 'package:events_amo/services/navigation_service.dart';
import 'package:events_amo/services/notification_service.dart';
import 'package:events_amo/services/user_profile_service.dart';
import 'package:events_amo/services/user_service.dart';
import 'package:events_amo/utils/width_constraint_wrapper.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final eventService = EventService(apiClient);
  final userService = UserService(apiClient);
  final profileService = UserProfileService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => EventProvider(eventService)),
        ChangeNotifierProvider(
          create: (_) => UserProvider(userService, profileService),
        ),
      ],
      child: EventsApp(),
    ),
  );
}

class EventsApp extends StatelessWidget {
  const EventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'NeoEvents',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF6200EA),
        scaffoldBackgroundColor: Color(0xFF0A0E21),
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6200EA),
          secondary: Color(0xFF00E5FF),
          tertiary: Color(0xFFFF00E5),
          surface: Color(0xFF0A0E21),
          onSurface: Colors.white,
        ),
      ),
      home: WidthConstraintWrapper(child: MainPage()),
      debugShowCheckedModeBanner: false,
    );
  }
}
