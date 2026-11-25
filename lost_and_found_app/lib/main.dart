import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lost_and_found_app/UserAccess.dart';
import 'package:lost_and_found_app/auth_service.dart';
import 'package:lost_and_found_app/firebase_options.dart';
import 'package:lost_and_found_app/lost_report.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthService.connectToEmulators();
    final user = await AuthService.restoreSession();
    if (user != null) LostReportSession.signIn(user.email);
    runApp(LostAndFoundApp(isSignedIn: user != null));
  } on StateError catch (error) {
    runApp(FirebaseSetupRequiredApp(message: error.message.toString()));
  } on UnsupportedError catch (error) {
    runApp(FirebaseSetupRequiredApp(message: error.message.toString()));
  } on FirebaseException catch (error) {
    runApp(
      FirebaseSetupRequiredApp(
        message:
            'Firebase initialization failed: ${error.message ?? error.code}',
      ),
    );
  }
}

class LostAndFoundApp extends StatelessWidget {
  const LostAndFoundApp({super.key, required this.isSignedIn});

  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Lost and Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1D4E89),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        fontFamily: 'Roboto',
      ),
      home: isSignedIn ? const MyReportsPage() : const LoginPage(),
    );
  }
}

class FirebaseSetupRequiredApp extends StatelessWidget {
  const FirebaseSetupRequiredApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase setup required',
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firebase setup required',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(message),
                  const SizedBox(height: 12),
                  const Text(
                    'Configure Firebase for this project and provide the '
                    'required platform app IDs before launching the app.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
