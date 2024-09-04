import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_textfield.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';

class ResetPassword extends StatefulWidget {
  final String token;

  const ResetPassword({super.key, required this.token});

  @override
  ResetPasswordState createState() => ResetPasswordState();
}

class ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPassword != _confirmPassword) {
        Fluttertoast.showToast(
          msg: "Passwords do not match",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      setState(() => _isLoading = true);
      bool success =
          await Auth.confirmResetPassword(widget.token, _newPassword);
      setState(() => _isLoading = false);
      if (success) {
        Fluttertoast.showToast(
          msg: "Password reset successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Fluttertoast.showToast(
          msg: "Failed to reset password",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _formKey.currentState?.reset();
      _newPassword = '';
      _confirmPassword = '';
    });
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                                  'Reset Password',
                                  style: AppTextStyles.headingStyleWithShadow,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Enter your new password.',
                                  style: AppTextStyles.subheadingStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 60),
                              CustomTextField(
                                hintText: 'New Password',
                                obscureText: _obscureNewPassword,
                                onChanged: (value) => _newPassword = value,
                                validator: (value) => value!.isEmpty
                                    ? 'Enter new password'
                                    : null,
                                focusNode: _newPasswordFocusNode,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context)
                                      .requestFocus(_confirmPasswordFocusNode);
                                },
                                prefixIcon: Icons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureNewPassword =
                                          !_obscureNewPassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                hintText: 'Confirm Password',
                                obscureText: _obscureConfirmPassword,
                                onChanged: (value) => _confirmPassword = value,
                                validator: (value) => value!.isEmpty
                                    ? 'Confirm your password'
                                    : null,
                                focusNode: _confirmPasswordFocusNode,
                                onFieldSubmitted: (_) => _resetPassword(),
                                prefixIcon: Icons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              AnimatedButton(
                                text: 'Reset Password',
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
