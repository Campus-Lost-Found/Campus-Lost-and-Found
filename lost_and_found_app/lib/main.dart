import 'package:material_ui/material_ui.dart';
import 'package:lost_and_found_app/UserAccess.dart';

void main() => runApp(const LostAndFoundApp());

class LostAndFoundApp extends StatelessWidget {
  const LostAndFoundApp({super.key});

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
      home: const LoginPage(),
    );
  }
}
