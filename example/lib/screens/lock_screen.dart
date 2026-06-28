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
  static const _pin = '1234';

  String _enteredPin = '';
  String? _errorText;

  void _onNumberPressed(String value) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
      _errorText = null;
    });

    if (_enteredPin.length == 4) {
      _checkPin();
    }
  }

  void _backspace() {
    if (_enteredPin.isEmpty) return;

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _checkPin() async {
    if (_enteredPin == _pin) {
      LocalStorage.isLockedOut = false;

      if (!mounted) return;

      await Navigator.pushReplacement(context, MaterialPageRoute<HomeScreen>(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        _enteredPin = '';
        _errorText = 'Incorrect PIN';
      });
    }
  }

  Widget _buildPinDot(int index) {
    final filled = index < _enteredPin.length;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? Colors.blue : Colors.transparent,
          border: Border.all(color: filled ? Colors.blue : Colors.grey, width: 2),
        ),
      ),
    );
  }

  Widget _numberButton(String value) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () => _onNumberPressed(value),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _keypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_numberButton('1'), _numberButton('2'), _numberButton('3')],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_numberButton('4'), _numberButton('5'), _numberButton('6')],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_numberButton('7'), _numberButton('8'), _numberButton('9')],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72),
            _numberButton('0'),
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _backspace,
              child: const SizedBox(width: 72, height: 72, child: Icon(Icons.backspace_outlined)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72, fontWeight: FontWeight.w300),
                const SizedBox(height: 24),
                const Text('App Locked', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text('Enter your PIN to continue', textAlign: TextAlign.center),
                const SizedBox(height: 36),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, _buildPinDot)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 24,
                  child: Text(_errorText ?? '', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 24),
                _keypad(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
