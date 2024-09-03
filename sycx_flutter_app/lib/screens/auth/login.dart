import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      bool success = await Auth.login(_username, _password);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(
          msg: "Login failed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: (value) => _username = value,
              validator: (value) => value!.isEmpty ? 'Enter username' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => _password = value,
              validator: (value) => value!.isEmpty ? 'Enter password' : null,
            ),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
