import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _smsCode = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;

  Future<void> _sendCode() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phone.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.pushReplacementNamed(context, '/home');
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyCode() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _smsCode.text,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone Login")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone (+94...)'),
              keyboardType: TextInputType.phone,
            ),
            if (_codeSent)
              TextField(
                controller: _smsCode,
                decoration: const InputDecoration(labelText: 'SMS Code'),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _codeSent ? _verifyCode : _sendCode,
              child: Text(_codeSent ? "Verify Code" : "Send Code"),
            ),
          ],
        ),
      ),
    );
  }
}
