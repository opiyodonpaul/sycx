import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/screens/auth/forgot_password.dart';
import 'package:sycx_flutter_app/screens/auth/login.dart';
import 'package:sycx_flutter_app/screens/auth/register.dart';
import 'package:sycx_flutter_app/screens/profile.dart';
import 'package:sycx_flutter_app/screens/search_results.dart';
import 'package:sycx_flutter_app/screens/splash.dart';
import 'package:sycx_flutter_app/screens/summaries.dart';
import 'package:sycx_flutter_app/screens/summary_details.dart';
import 'package:sycx_flutter_app/screens/upload.dart';
import 'package:sycx_flutter_app/screens/view_summary.dart';
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
        '/register': (context) => const Register(),
        '/login': (context) => const Login(),
        '/forgot_password': (context) => const ForgotPassword(),
        '/home': (context) => const Home(),
        '/search': (context) => const SearchResults(searchQuery: ''),
        '/summary_details': (context) => const SummaryDetails(
              summary: {},
            ),
        '/view_summary': (context) => const ViewSummary(
              summary: {},
            ),
        '/upload': (context) => const Upload(),
        '/summaries': (context) => const Summaries(),
        '/profile': (context) => const Profile(),
      },
    );
  }
}
