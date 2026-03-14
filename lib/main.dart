import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local notifications
  await NotificationService.initialize();

  // Initialize FCM (permission + listeners)
  await FirebaseMessagingService.initialize();

  if (SupabaseConfig.useSupabase) {
    await SupabaseService.initialize();
  }

  runApp(const CampusFlowApp());
}

class CampusFlowApp extends StatelessWidget {
  const CampusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If Supabase is enabled and user has an active session, go straight to chat
    final bool hasSession = SupabaseConfig.useSupabase &&
        SupabaseService.instance.isLoggedIn;

    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'CampusFlow AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: hasSession
            ? const _AutoLoginWrapper()
            : const LoginScreen(),
      ),
    );
  }
}

/// Automatically logs in the user from the persisted Supabase session
/// and then shows the ChatScreen.
class _AutoLoginWrapper extends StatefulWidget {
  const _AutoLoginWrapper();

  @override
  State<_AutoLoginWrapper> createState() => _AutoLoginWrapperState();
}

class _AutoLoginWrapperState extends State<_AutoLoginWrapper> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.restoreSupabaseSession();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.loginGradient),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
