// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:idle_logout_sample/screens/home_screen.dart';
import 'package:idle_logout_sample/utils.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  String? _errorText;

  void _checkPin() {
    if (_pinController.text == '1234') {
      LocalStorage.isLockedOut = false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<HomeScreen>(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorText = 'Incorrect PIN, try again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter your 4-digit PIN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '****',
                  errorText: _errorText,
                  counterText: '',
                ),
                onSubmitted: (_) => _checkPin(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _checkPin, child: const Text('Unlock')),
            ],
          ),
        ),
      ),
    );
  }
}
