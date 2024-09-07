import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';

class CustomAppBarMini extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBarMini({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
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
        child: AppBar(
          title: Text(
            title,
            style: AppTextStyles.titleStyle,
          ),
          backgroundColor: Colors.transparent, // Transparent to show gradient
          elevation: 0, // Remove shadow if needed
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
