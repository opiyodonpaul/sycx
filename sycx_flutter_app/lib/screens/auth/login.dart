import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String _username = '';
  String _password = '';
  bool _obscurePassword = true;

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

  Future<void> _handleRefresh() async {
    setState(() {
      _formKey.currentState?.reset();
      _username = '';
      _password = '';
    });
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientMiddle,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Text(
                            'Welcome Back',
                            style: AppTextStyles.headingStyleWithShadow,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Login to continue summarizing the world.',
                            style: AppTextStyles.subheadingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 60),
                        CustomTextField(
                          hintText: 'Username',
                          onChanged: (value) => _username = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter username' : null,
                          focusNode: _usernameFocusNode,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_passwordFocusNode);
                          },
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          onChanged: (value) => _password = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter password' : null,
                          focusNode: _passwordFocusNode,
                          onFieldSubmitted: (_) => _login(),
                          prefixIcon: Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedButton(
                          text: 'Login',
                          onPressed: _login,
                          backgroundColor: AppColors.primaryButtonColor,
                          textColor: AppColors.primaryButtonTextColor,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/register');
                            },
                            child: Text(
                              'Don\'t have an account? Sign up',
                              style: AppTextStyles.bodyTextStyle.copyWith(
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
