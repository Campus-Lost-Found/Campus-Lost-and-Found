import 'package:material_ui/material_ui.dart';

import 'UserAccess.dart';
import 'auth_service.dart';
import 'lost_report.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  final user = await AuthService.restoreSession();
  if (user != null) LostReportSession.signIn(user.email);
  runApp(LostAndFoundApp(isSignedIn: user != null));
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
