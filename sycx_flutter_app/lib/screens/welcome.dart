import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
