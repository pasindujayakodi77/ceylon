import 'package:flutter/material.dart';

class BusinessCreateScreen extends StatelessWidget {
  const BusinessCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Business'),
      ),
      body: const Center(
        child: Text('This is the create business screen'),
      ),
    );
  }
}
