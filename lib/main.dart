import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';import 'firebase_options.dart';
import 'package:mylove/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:mylove/service/AudioPlayerService.dart'; // Import your audio service (adjust path if needed)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return ChangeNotifierProvider( // Wrap MaterialApp with ChangeNotifierProvider
create: (context) => AudioPlayerService(),
child: MaterialApp(
title: 'Our Love Quiz',
theme: ThemeData(
primarySwatch: Colors.pink,
// fontFamily: GoogleFonts.greatVibes().fontFamily,
),
home: const SplashScreen(),
),
);
}
}