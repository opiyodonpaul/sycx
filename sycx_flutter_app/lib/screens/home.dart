import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Auth.logout();
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}
