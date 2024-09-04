import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/screens/auth/forgot_password.dart';
import 'package:sycx_flutter_app/screens/auth/login.dart';
import 'package:sycx_flutter_app/screens/auth/register.dart';
import 'package:sycx_flutter_app/screens/auth/reset_password.dart';
import 'package:sycx_flutter_app/screens/splash.dart';
import 'package:sycx_flutter_app/screens/welcome.dart';
import 'package:sycx_flutter_app/screens/home.dart';
import 'dart:async';

import 'package:uni_links2/uni_links.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.path == '/reset-password') {
        String? token = uri.queryParameters['token'];
        if (token != null) {
          Navigator.of(context).pushNamed('/reset_password', arguments: token);
        }
      }
    }, onError: (err) {
      print('Error processing incoming link: $err');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
        '/register': (context) => const Register(),
        '/login': (context) => const Login(),
        '/forgot_password': (context) => const ForgotPassword(),
        '/reset_password': (context) => ResetPassword(
            token: ModalRoute.of(context)!.settings.arguments as String),
        '/home': (context) => const Home(),
      },
    );
  }
}
