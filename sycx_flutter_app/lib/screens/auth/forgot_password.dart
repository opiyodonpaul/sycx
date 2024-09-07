import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  ForgotPasswordState createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  String _email = '';
  bool _isLoading = false;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      bool success = await Auth.resetPassword(_email);
      setState(() => _isLoading = false);
      if (success) {
        Fluttertoast.showToast(
          msg: "Password reset link sent to your email",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.gradientMiddle,
          textColor: Colors.white,
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Fluttertoast.showToast(
          msg: "Failed to send password reset link",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.gradientMiddle,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _formKey.currentState?.reset();
      _email = '';
    });
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        body: _isLoading
            ? const Loading()
            : RefreshIndicator(
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
                                  'Forgot Password',
                                  style: AppTextStyles.headingStyleWithShadow,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Enter your email to reset your password.',
                                  style: AppTextStyles.subheadingStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 60),
                              CustomTextField(
                                hintText: 'Email',
                                onChanged: (value) => _email = value,
                                validator: (value) =>
                                    value!.isEmpty ? 'Enter email' : null,
                                focusNode: _emailFocusNode,
                                onFieldSubmitted: (_) => _resetPassword(),
                                prefixIcon: Icons.email,
                              ),
                              const SizedBox(height: 24),
                              AnimatedButton(
                                text: 'Send Reset Link',
                                onPressed: _resetPassword,
                                backgroundColor: AppColors.primaryButtonColor,
                                textColor: AppColors.primaryButtonTextColor,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/login');
                                  },
                                  child: Text(
                                    'Back to Login',
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
