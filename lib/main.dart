import 'package:flutter/material.dart';

void main() {
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
