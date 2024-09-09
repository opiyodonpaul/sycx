import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';
import 'package:sycx_flutter_app/widgets/padded_round_slider_value_indicator_shape.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  UploadState createState() => UploadState();
}

class UploadState extends State<Upload> with SingleTickerProviderStateMixin {
  List<PlatformFile> uploadedFiles = [];
  double summaryDepth = 0;
  bool isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        uploadedFiles.addAll(result.files);
      });
    }
  }

  void removeFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
  }

  Future<void> summarize() async {
    if (uploadedFiles.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please upload at least one file",
        backgroundColor: AppColors.gradientMiddle,
        textColor: AppColors.primaryTextColor,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      const userId = 'artkins10';
      List<Summary> summaries = [];

      for (var file in uploadedFiles) {
        final summary = await SummaryService.summarizeDocument(userId, file);
        summaries.add(summary);
      }

      setState(() {
        isLoading = false;
      });

      // Navigate to a new screen to display the summary
      Navigator.pushNamed(context, '/summaries', arguments: summaries);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Failed to summarize documents: ${e.toString()}",
        backgroundColor: AppColors.gradientEnd,
        textColor: AppColors.primaryTextColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        user: DummyData.user,
        showBackground: false,
        title: 'SycX',
      ),
      body: isLoading ? const Loading() : _buildBody(),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: '/upload',
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          uploadedFiles.clear();
          summaryDepth = 0;
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInstructions(),
                  const SizedBox(height: defaultMargin),
                  _buildUploadArea(),
                  const SizedBox(height: defaultMargin),
                  _buildPreviewContent(),
                  const SizedBox(height: defaultMargin),
                  _buildSummarizationPreferences(),
                  const SizedBox(height: defaultMargin),
                  _buildSummarizeButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController, curve: Curves.easeOut))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController, curve: Curves.easeOut))
                .value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Content',
              style: AppTextStyles.headingStyleWithShadow,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your files and let SycX summarize them for you.',
              style: AppTextStyles.subheadingStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: Card(
        color: AppColors.textFieldFillColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use:',
                style: AppTextStyles.titleStyle
                    .copyWith(color: AppColors.primaryTextColor),
              ),
              const SizedBox(height: 8),
              _buildInstructionStep('1. Upload your files'),
              _buildInstructionStep('2. Preview and confirm'),
              _buildInstructionStep('3. Set summary depth'),
              _buildInstructionStep('4. Click Summarize'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.gradientStart, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: AppTextStyles.bodyTextStyle
                  .copyWith(color: AppColors.primaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: pickFiles,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            padding: const EdgeInsets.all(2),
            color: AppColors.textFieldBorderColor,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryTextColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload,
                        size: 48, color: AppColors.gradientStart),
                    const SizedBox(height: 16),
                    Text(
                      'Drag & Drop or Click to Upload',
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.textFieldFillColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supports all file types',
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.textFieldFillColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Content (${DummyData.uploadedFiles.length} files)',
            style: AppTextStyles.titleStyle,
          ),
          DummyData.uploadedFiles.isEmpty
              ? Card(
                  elevation: 2,
                  color: AppColors.textFieldFillColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    leading: const Icon(
                      Icons.cloud_upload,
                      color: AppColors.primaryButtonColor,
                      size: 28,
                    ),
                    title: Text(
                      "No files uploaded yet",
                      style: AppTextStyles.bodyTextStyle,
                    ),
                    subtitle: Text(
                      "Upload files to see them here",
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: DummyData.uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = DummyData.uploadedFiles[index];
                    return Card(
                      color: AppColors.textFieldFillColor,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(_getFileIcon(file['type']),
                            color: AppColors.gradientMiddle),
                        title: Text(file['name']!,
                            style: AppTextStyles.bodyTextStyle),
                        subtitle: Text(file['size']!,
                            style: AppTextStyles.bodyTextStyle
                                .copyWith(color: AppColors.secondaryTextColor)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppColors.gradientEnd),
                          onPressed: () => removeFile(index),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSummarizationPreferences() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.8, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.8, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary Depth',
            style: AppTextStyles.titleStyle
                .copyWith(color: AppColors.primaryTextColorDark),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Color.lerp(AppColors.gradientStart,
                  AppColors.gradientEnd, summaryDepth / 3),
              inactiveTrackColor: AppColors.secondaryTextColor.withOpacity(0.3),
              thumbColor: Color.lerp(AppColors.gradientStart,
                  AppColors.gradientEnd, summaryDepth / 3),
              overlayColor: Color.lerp(AppColors.gradientStart,
                      AppColors.gradientEnd, summaryDepth / 3)
                  ?.withOpacity(0.3),
              valueIndicatorColor: Color.lerp(AppColors.gradientStart,
                  AppColors.gradientEnd, summaryDepth / 3),
              valueIndicatorTextStyle: AppTextStyles.bodyTextStyle,
              valueIndicatorShape: const PaddedRoundSliderValueIndicatorShape(
                  padding: EdgeInsets.symmetric(horizontal: 16.0)),
            ),
            child: Slider(
              value: summaryDepth,
              onChanged: (value) {
                setState(() {
                  summaryDepth = value;
                });
              },
              min: 0,
              max: 3,
              divisions: 3,
              label: _getSummaryDepthLabel(),
            ),
          ),
          Text(
            'Selected: ${_getSummaryDepthLabel()}',
            style: AppTextStyles.bodyTextStyle
                .copyWith(color: AppColors.primaryTextColorDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarizeButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Tween<Offset>(
            begin: const Offset(0, 50),
            end: Offset.zero,
          )
              .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.9, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.9, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: AnimatedButton(
        text: 'Summarize',
        onPressed: summarize,
        backgroundColor: AppColors.primaryButtonColor,
        textColor: AppColors.primaryButtonTextColor,
      ),
    );
  }

  String _getSummaryDepthLabel() {
    switch (summaryDepth.round()) {
      case 0:
        return 'Brief';
      case 1:
        return 'Moderate';
      case 2:
        return 'Detailed';
      case 3:
        return 'Comprehensive';
      default:
        return '';
    }
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'xlsx':
        return Icons.table_chart;
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }
}
