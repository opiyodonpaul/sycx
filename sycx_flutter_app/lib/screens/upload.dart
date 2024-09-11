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
  double _progress = 0.0;
  int _currentFileIndex = 0;

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
      _progress = 0.0;
      _currentFileIndex = 0;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldFillColor,
              title: Text(
                'Summarizing',
                style: AppTextStyles.titleStyle
                    .copyWith(color: AppColors.primaryTextColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor:
                        AppColors.secondaryTextColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(AppColors.gradientStart, AppColors.gradientEnd,
                          _progress)!,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.bodyTextStyle
                        .copyWith(color: AppColors.primaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Summarizing file ${_currentFileIndex + 1} of ${uploadedFiles.length}',
                    style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.primaryTextColor, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      const userId = 'artkins10';
      List<Summary> summaries = [];

      for (var i = 0; i < uploadedFiles.length; i++) {
        final file = uploadedFiles[i];
        final summary = await SummaryService.summarizeDocument(
          userId,
          file,
          (progress) {
            setState(() {
              _progress = (i + progress) / uploadedFiles.length;
              _currentFileIndex = i;
            });
          },
        );
        summaries.add(summary);
      }

      Navigator.of(context).pop();

      Navigator.pushNamed(context, '/summaries');
    } catch (e) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Failed to summarize documents: ${e.toString()}",
        backgroundColor: AppColors.gradientEnd,
        textColor: AppColors.primaryTextColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Loading()
        : Scaffold(
            extendBodyBehindAppBar: true,
            appBar: CustomAppBar(
              user: DummyData.user,
              showBackground: false,
              title: 'SycX',
            ),
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildBody(),
              ),
            ),
            bottomNavigationBar: const CustomBottomNavBar(
              currentRoute: '/upload',
            ),
          );
  }

  Widget _buildBody() {
    return Column(
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
        const SizedBox(height: 8),
      ],
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
              _buildInstructionStep('2. Set summary depth'),
              _buildInstructionStep('3. Click Summarize'),
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
            'Preview Content (${uploadedFiles.length} files)',
            style: AppTextStyles.titleStyle,
          ),
          uploadedFiles.isEmpty
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
                  itemCount: uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = uploadedFiles[index];
                    return Card(
                      color: AppColors.textFieldFillColor,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(_getFileIcon(file.extension),
                            color: AppColors.gradientMiddle),
                        title:
                            Text(file.name, style: AppTextStyles.bodyTextStyle),
                        subtitle: Text(
                            '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
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
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      uploadedFiles.clear();
      summaryDepth = 0;
    });
  }
}
