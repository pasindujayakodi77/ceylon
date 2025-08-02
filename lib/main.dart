import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

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
      home: const Scaffold(
        body: Center(child: Text('🧭 Welcome to CEYLON App')),
      ),
    );
  }
}
