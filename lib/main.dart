import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import the generated file
import 'package:mylove/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import the package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//   } catch (e) {
//     print('Error initializing Firebase: $e');
//   }
//   runApp(const MyApp());
// }

// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Love Quiz',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: GoogleFonts.dancingScript().fontFamily, // Use Google Fonts
      ),
      home: const SplashScreen(),
    );
  }
}
