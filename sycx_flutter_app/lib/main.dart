import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/screens/auth/login.dart';
import 'package:sycx_flutter_app/screens/auth/register.dart';
import 'package:sycx_flutter_app/screens/splash.dart';
import 'package:sycx_flutter_app/screens/welcome.dart';
import 'package:sycx_flutter_app/screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SycX',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Splash(),
      routes: {
        '/welcome': (context) => const Welcome(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/home': (context) => const Home(),
      },
    );
  }
}
