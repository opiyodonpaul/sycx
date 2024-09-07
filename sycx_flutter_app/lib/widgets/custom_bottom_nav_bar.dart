import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const CustomBottomNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMiddle,
            AppColors.gradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(80),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.home, 'Home', '/home'),
            _buildNavItem(Icons.upload, 'Upload', '/upload'),
            _buildNavItem(
                Icons.my_library_books_rounded, 'Summaries', '/summaries'),
          ],
          onTap: (index) {
            String route = ['/home', '/upload', '/summaries'][index];
            if (route != currentRoute) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          currentIndex: _getCurrentIndex(),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    String route,
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: currentRoute == route
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 24,
        ),
      ),
      label: label,
    );
  }

  int _getCurrentIndex() {
    switch (currentRoute) {
      case '/home':
        return 0;
      case '/upload':
        return 1;
      case '/summaries':
        return 2;
      default:
        return 0;
    }
  }
}
