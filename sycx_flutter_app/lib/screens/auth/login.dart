import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/loading_widget.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    bool success = await Auth.login(_email, _password);

    setState(() {
      _loading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Login failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Loading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextField(
                      hintText: 'Email',
                      onChanged: (value) => _email = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter an email' : null,
                    ),
                    CustomTextField(
                      hintText: 'Password',
                      obscureText: true,
                      onChanged: (value) => _password = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter a password' : null,
                    ),
                    const SizedBox(height: 20),
                    AnimatedButton(
                      text: 'Login',
                      onPressed: _login,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reset_password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
