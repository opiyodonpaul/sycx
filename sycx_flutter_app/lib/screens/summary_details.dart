import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/screens/view_summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_textarea.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';

class SummaryDetails extends StatefulWidget {
  final Map<String, dynamic> summary;

  const SummaryDetails({super.key, required this.summary});

  @override
  SummaryDetailsState createState() => SummaryDetailsState();
}

class SummaryDetailsState extends State<SummaryDetails> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBarMini(
              title: widget.summary['title'] ?? 'Summary Details'),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardImage(widget.summary['image'] as String? ?? ''),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.summary['title'] ?? 'Untitled Summary',
                          style: AppTextStyles.headingStyleNoShadow
                              .copyWith(color: AppColors.primaryTextColorDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created on ${DateFormat('MMM d, yyyy').format(DateTime.parse(widget.summary['date'] as String? ?? DateTime.now().toIso8601String()))}',
                          style: AppTextStyles.bodyTextStyle
                              .copyWith(color: AppColors.altPriTextColorDark),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Actions',
                          style: AppTextStyles.titleStyle,
                        ),
                        const SizedBox(height: 16),
                        OpenContainer(
                          transitionDuration: const Duration(milliseconds: 500),
                          openBuilder: (context, _) =>
                              ViewSummary(summary: widget.summary),
                          closedBuilder: (context, openContainer) =>
                              AnimatedButton(
                            text: 'View Summary',
                            onPressed: openContainer,
                            backgroundColor: AppColors.gradientStart,
                            textColor: AppColors.primaryButtonTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedButton(
                          text: 'Download Summary',
                          onPressed: () => _downloadSummary(context),
                          backgroundColor: AppColors.gradientMiddle,
                          textColor: AppColors.primaryButtonTextColor,
                        ),
                        const SizedBox(height: 12),
                        AnimatedButton(
                          text: 'Delete Summary',
                          onPressed: () => _deleteSummary(context),
                          backgroundColor: AppColors.gradientEnd,
                          textColor: AppColors.primaryButtonTextColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Rate this Summary',
                          style: AppTextStyles.titleStyle,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 1; i <= 5; i++)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = i.toDouble();
                                  });
                                },
                                child: Icon(
                                  i <= _rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextArea(
                          controller: _reviewController,
                          hintText:
                              'Share your feedback on this summary and suggest improvements for future summaries.',
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        AnimatedButton(
                          text: 'Submit Review',
                          onPressed: _submitReview,
                          backgroundColor: AppColors.primaryButtonColor,
                          textColor: AppColors.primaryButtonTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const CustomBottomNavBar(),
        ),
        if (_isLoading) const Loading(),
      ],
    );
  }

  Widget _buildCardImage(String imageUrl) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/card.png',
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Future<void> _downloadSummary(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      // Simulate download process
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "Summary downloaded",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.gradientMiddle,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSummary(BuildContext context) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldFillColor,
          title: Text(
            'Delete Summary',
            style: AppTextStyles.titleStyle
                .copyWith(color: AppColors.primaryTextColor),
          ),
          content: Text(
            'Are you sure you want to delete this summary?',
            style: AppTextStyles.bodyTextStyle
                .copyWith(color: AppColors.primaryTextColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonTextStyle,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientEnd,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTextStyles.buttonTextStyle,
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      try {
        // Simulate deletion process
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: "Summary deleted",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.gradientMiddle,
          textColor: Colors.white,
        );
        // Here you would typically navigate back or refresh the list
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement review submission logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "Review submitted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.gradientMiddle,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
