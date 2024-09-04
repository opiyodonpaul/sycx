import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/screens/auth/login.dart';
import 'package:sycx_flutter_app/screens/auth/register.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  void _navigateWithAnimation(BuildContext context, String routeName) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            routeName == '/register' ? const Register() : const Login(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        // Do nothing as this is the initial screen
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
              child: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1517971071642-34a2d3ecc9cd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1288&q=80',
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              width: double.infinity,
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
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryButtonColor),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.gradientStart.withOpacity(0.6),
                              AppColors.gradientMiddle.withOpacity(0.6),
                              AppColors.gradientEnd.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Summarize the world,\nin minutes.',
                          style: AppTextStyles.headingStyleWithShadow,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Read and listen to the key points from top\nnews, articles, and books.',
                          style: AppTextStyles.subheadingStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        AnimatedButton(
                          text: 'Sign up',
                          onPressed: () =>
                              _navigateWithAnimation(context, '/register'),
                          backgroundColor: AppColors.primaryButtonColor,
                          textColor: AppColors.primaryButtonTextColor,
                        ),
                        const SizedBox(height: 20),
                        AnimatedButton(
                          text: 'Log in',
                          onPressed: () =>
                              _navigateWithAnimation(context, '/login'),
                          backgroundColor: AppColors.secondaryButtonColor,
                          textColor: AppColors.secondaryButtonTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
