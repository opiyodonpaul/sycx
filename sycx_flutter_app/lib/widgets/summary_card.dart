import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/screens/summary_details.dart';

class SummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final Function(String) onTogglePin;
  final bool isEmpty;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.onTogglePin,
    this.isEmpty = false,
  });

  String _getCardTitle() {
    if (isEmpty) return 'Create Summary';

    return summary['title']?.toString() ??
        (summary['originalDocuments'] as List?)
            ?.firstOrNull?['title']
            ?.toString() ??
        'Untitled';
  }

  String _getFormattedDate() {
    try {
      final createdAt = summary['date'] ?? summary['createdAt'];
      if (createdAt != null) {
        final DateTime date = DateTime.parse(createdAt.toString());
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return 'Date not available';
  }

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pushReplacementNamed('/upload'),
        child: _buildCardContent(context),
      );
    }

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 500),
      openBuilder: (context, _) => SummaryDetails(summary: summary),
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: _buildCardContent(context),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final cardTitle = _getCardTitle();
    final dateStr = _getFormattedDate();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCardImage(),
                _buildGradientOverlay(),
                _buildCardInfo(cardTitle, dateStr),
              ],
            ),
          ),
        ),
        if (!isEmpty) _buildPinButton(),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo(String title, String date) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subheadingStyle.copyWith(
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmpty ? 'Create your first summary!' : 'Created on $date',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () => onTogglePin(summary['id']?.toString() ?? ''),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            summary['isPinned'] == true
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            key: ValueKey<bool>(summary['isPinned'] == true),
            color: AppColors.primaryButtonColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    final imageUrl = summary['imageUrl'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator();
        },
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.description,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
