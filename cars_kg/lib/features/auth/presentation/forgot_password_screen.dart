import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Enter your email and we will send you reset instructions.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 18),
              TextField(decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Send reset link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
