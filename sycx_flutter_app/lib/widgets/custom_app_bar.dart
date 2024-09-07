import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/user_avatar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackground;
  final String title;
  final Map<String, String> user;

  const CustomAppBar({
    super.key,
    required this.showBackground,
    required this.title,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          backgroundColor: showBackground
              ? Colors.white.withOpacity(0.8)
              : Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientStart.withOpacity(showBackground ? 0.2 : 0),
                  AppColors.gradientEnd.withOpacity(showBackground ? 0.2 : 0),
                ],
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  height: 40,
                  width: 40,
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: AppTextStyles.headingStyleNoShadow.copyWith(
                        color: showBackground
                            ? Colors.black87
                            : AppColors.primaryTextColor)),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: UserAvatar(user: user),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
