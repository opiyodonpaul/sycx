import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sycx_flutter_app/screens/view_summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_textarea.dart';

class SummaryDetails extends StatefulWidget {
  final Map<String, dynamic> summary;

  const SummaryDetails({super.key, required this.summary});

  @override
  SummaryDetailsState createState() => SummaryDetailsState();
}

class SummaryDetailsState extends State<SummaryDetails> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarMini(title: widget.summary['title']!),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.summary['image']!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.summary['title']!,
                    style: AppTextStyles.headingStyleNoShadow
                        .copyWith(color: AppColors.primaryTextColorDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created on ${DateFormat('MMM d, yyyy').format(DateTime.parse(widget.summary['date']!))}',
                    style: AppTextStyles.bodyTextStyle
                        .copyWith(color: AppColors.altPriTextColorDark),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Actions',
                    style: AppTextStyles.titleStyle,
                  ),
                  const SizedBox(height: 16),
                  AnimatedButton(
                    text: 'View Summary',
                    onPressed: () => _viewSummary(context),
                    backgroundColor: AppColors.primaryButtonColor,
                    textColor: AppColors.primaryButtonTextColor,
                  ),
                  const SizedBox(height: 12),
                  AnimatedButton(
                    text: 'Download Summary',
                    onPressed: () => _downloadSummary(context),
                    backgroundColor: AppColors.primaryButtonColor,
                    textColor: AppColors.primaryButtonTextColor,
                  ),
                  const SizedBox(height: 12),
                  AnimatedButton(
                    text: 'Delete Summary',
                    onPressed: () => _deleteSummary(context),
                    backgroundColor: Colors.red,
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
    );
  }

  void _viewSummary(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ViewSummary(
          summary: {},
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _downloadSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Downloading', style: AppTextStyles.titleStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: AppColors.primaryButtonColor),
              const SizedBox(height: 16),
              Text(
                'Downloading summary...',
                style: AppTextStyles.bodyTextStyle
                    .copyWith(color: AppColors.primaryTextColorDark),
              ),
            ],
          ),
        );
      },
    );

    // Simulate download process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the download dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Summary downloaded', style: AppTextStyles.bodyTextStyle),
          backgroundColor: AppColors.gradientMiddle,
        ),
      );
    });
  }

  void _deleteSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Summary', style: AppTextStyles.titleStyle),
          content: Text(
            'Are you sure you want to delete this summary?',
            style: AppTextStyles.bodyTextStyle
                .copyWith(color: AppColors.primaryTextColorDark),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.primaryButtonColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                // Show deletion animation
                _showDeletionAnimation(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeletionAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Deleting summary...',
                style: AppTextStyles.bodyTextStyle
                    .copyWith(color: AppColors.primaryTextColorDark),
              ),
            ],
          ),
        );
      },
    );

    // Simulate deletion process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the deletion dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Summary deleted', style: AppTextStyles.bodyTextStyle),
          backgroundColor: AppColors.gradientMiddle,
        ),
      );
      // Here you would typically navigate back or refresh the list
    });
  }

  void _submitReview() {
    // TODO: Implement review submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review submitted successfully',
            style: AppTextStyles.bodyTextStyle),
        backgroundColor: AppColors.gradientMiddle,
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
