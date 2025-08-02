import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:ceylon/core/theme/theme.dart'; // we'll create this later

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CeylonApp());
}

class CeylonApp extends StatelessWidget {
  const CeylonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEYLON',
      debugShowCheckedModeBanner: false,
      //theme: CeylonTheme.light, // optional if not using themes yet
      home: const Scaffold(
        body: Center(child: Text('🧭 CEYLON App Firebase Ready')),
      ),
    );
  }
}
