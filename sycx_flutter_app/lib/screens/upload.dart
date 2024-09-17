import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/padded_round_slider_value_indicator_shape.dart';
import 'package:dotted_border/dotted_border.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  UploadState createState() => UploadState();
}

class UploadState extends State<Upload> with TickerProviderStateMixin {
  List<PlatformFile> uploadedFiles = [];
  double summaryDepth = 0;
  bool isLoading = false;
  late AnimationController _animationController;
  late AnimationController _loadingAnimationController;
  late AnimationController _deleteAnimationController;
  double _progress = 0.0;
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Swahili',
    'Spanish',
    'French',
    'German',
  ];
  String _currentStepName = '';
  PlatformFile? _previewFile;
  bool _mergeSummaries = false;
  String? _filePreviewContent;
  int _totalSteps = 0;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _deleteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
    CustomBottomNavBar.updateLastMainRoute('/upload');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingAnimationController.dispose();
    _deleteAnimationController.dispose();
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
    _deleteAnimationController.forward(from: 0).then((_) {
      setState(() {
        uploadedFiles.removeAt(index);
      });
      _deleteAnimationController.reverse();
    });
  }

  Future<void> summarize() async {
    if (uploadedFiles.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please upload at least one file",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.gradientMiddle,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _progress = 0.0;
      isLoading = true;
      _totalSteps =
          _mergeSummaries ? uploadedFiles.length + 1 : uploadedFiles.length;
      _currentStep = 0;
    });
    _loadingAnimationController.forward();

    try {
      if (_mergeSummaries) {
        // Merging process
        for (var i = 0; i < uploadedFiles.length; i++) {
          setState(() {
            _currentStep = i + 1;
            _currentStepName = 'Merging file ${i + 1}/${uploadedFiles.length}';
          });
          await _simulateMerging(uploadedFiles[i]);
        }

        // Summarize merged document
        setState(() {
          _currentStep = uploadedFiles.length + 1;
          _currentStepName = 'Summarizing merged document';
        });
        await _simulateSummarization(null, true);
      } else {
        // Summarize each file individually
        for (var i = 0; i < uploadedFiles.length; i++) {
          setState(() {
            _currentStep = i + 1;
            _currentStepName =
                'Summarizing file ${i + 1}/${uploadedFiles.length}';
          });
          await _simulateSummarization(uploadedFiles[i], false);
        }
      }

      setState(() {
        isLoading = false;
      });
      _loadingAnimationController.reverse();

      Navigator.pushNamed(context, '/summaries');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _loadingAnimationController.reverse();
      Fluttertoast.showToast(
        msg: "Failed to summarize documents: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.gradientMiddle,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _simulateMerging(PlatformFile file) async {
    final random = Random();
    final steps = 5 + random.nextInt(6); // 5 to 10 steps
    for (var i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: 100 + random.nextInt(200)));
      setState(() {
        _progress = (i + 1) / steps;
      });
    }
  }

  Future<void> _simulateSummarization(PlatformFile? file, bool isMerged) async {
    final random = Random();
    final depthFactor = summaryDepth + 1; // 1 to 4
    final fileSizeFactor = isMerged ? uploadedFiles.length : 1;
    final steps = (10 * depthFactor * fileSizeFactor).round();

    for (var i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: 50 + random.nextInt(100)));
      setState(() {
        _progress = (i + 1) / steps;
      });
    }
  }

  Future<void> _loadFilePreview(PlatformFile file) async {
    setState(() {
      _filePreviewContent = null;
    });

    if (file.extension?.toLowerCase() == 'txt') {
      final content = await File(file.path!).readAsString();
      setState(() {
        _filePreviewContent = content;
      });
    } else {
      setState(() {
        _filePreviewContent = "Preview not available for this file type.";
      });
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
      body: Stack(
        children: [
          _buildMainContent(),
          if (isLoading) _buildLoadingOverlay(),
          if (_previewFile != null) _buildPreviewOverlay(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: '/upload',
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return AnimatedBuilder(
      animation: _loadingAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingAnimationController.value,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                color: AppColors.textFieldFillColor.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: _progress,
                        backgroundColor:
                            AppColors.secondaryTextColor.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(AppColors.gradientStart,
                              AppColors.gradientEnd, _progress)!,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Color.lerp(AppColors.gradientStart,
                              AppColors.gradientEnd, _progress),
                          fontFamily: AppTextStyles.titleStyle.fontFamily,
                          fontSize: AppTextStyles.titleStyle.fontSize,
                          fontWeight: AppTextStyles.titleStyle.fontWeight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentStepName,
                        style: AppTextStyles.bodyTextStyle,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Step $_currentStep of $_totalSteps',
                        style:
                            AppTextStyles.bodyTextStyle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _previewFile = null;
          _filePreviewContent = null;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Card(
            color: AppColors.textFieldFillColor.withOpacity(0.9),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Preview: ${_previewFile!.name}',
                      style: AppTextStyles.titleStyle,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _filePreviewContent != null
                            ? Text(
                                _filePreviewContent!,
                                style: AppTextStyles.bodyTextStyle,
                              )
                            : const CircularProgressIndicator(),
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

  Widget _buildMainContent() {
    return SingleChildScrollView(
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
                _buildLanguageSelector(),
                const SizedBox(height: defaultMargin),
                _buildMergeSummariesToggle(),
                const SizedBox(height: defaultMargin),
                _buildSummarizeButton(),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
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
              _buildInstructionStep('2. Set summary depth'),
              _buildInstructionStep('3. Choose language'),
              _buildInstructionStep('4. Select merge option'),
              _buildInstructionStep('5. Click Summarize'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preview Content (${uploadedFiles.length} files)',
                style: AppTextStyles.titleStyle,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    uploadedFiles.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Clear All',
                  style: AppTextStyles.buttonTextStyle,
                ),
              ),
            ],
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
                    return AnimatedBuilder(
                      animation: _deleteAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 1 - _deleteAnimationController.value,
                          child: Transform.scale(
                            scale: 1 - (_deleteAnimationController.value * 0.2),
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        color: AppColors.textFieldFillColor,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Icon(_getFileIcon(file.extension),
                              color: AppColors.gradientMiddle),
                          title: Text(file.name,
                              style: AppTextStyles.bodyTextStyle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                style: AppTextStyles.bodyTextStyle.copyWith(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Wrap(
                                spacing: 4,
                                children: [
                                  _buildTag('Document'),
                                  const SizedBox(
                                    width: 1.5,
                                  ),
                                  _buildTag(file.extension?.toUpperCase() ??
                                      'Unknown'),
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.gradientEnd),
                                onPressed: () => removeFile(index),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _previewFile = file;
                            });
                            _loadFilePreview(file);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gradientMiddle.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyTextStyle.copyWith(
          fontSize: 10,
          color: AppColors.primaryTextColor,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: ${_getSummaryDepthLabel()}',
                style: AppTextStyles.bodyTextStyle
                    .copyWith(color: AppColors.primaryTextColorDark),
              ),
              Text(
                'Detail retained: ${_getDetailRetained()}',
                style: AppTextStyles.bodyTextStyle
                    .copyWith(color: AppColors.primaryTextColorDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary Language',
            style: AppTextStyles.titleStyle
                .copyWith(color: AppColors.primaryTextColorDark),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.textFieldFillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.textFieldBorderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppColors.primaryTextColor),
                iconSize: 24,
                elevation: 16,
                style: AppTextStyles.bodyTextStyle,
                dropdownColor: AppColors.textFieldFillColor,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                },
                items: _languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergeSummariesToggle() {
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
                  curve: const Interval(0.95, 1.0, curve: Curves.easeOut)))
              .value,
          child: Opacity(
            opacity: Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.95, 1.0, curve: Curves.easeOut)))
                .value,
            child: child,
          ),
        );
      },
      child: SwitchListTile(
        title: Text(
          'Merge Summaries',
          style: AppTextStyles.titleStyle
              .copyWith(color: AppColors.primaryTextColorDark),
        ),
        value: _mergeSummaries,
        onChanged: (bool value) {
          setState(() {
            _mergeSummaries = value;
          });
        },
        activeColor: AppColors.gradientStart,
        activeTrackColor: AppColors.gradientEnd,
        inactiveThumbColor: AppColors.secondaryTextColor,
        inactiveTrackColor: AppColors.gradientMiddle,
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

  String _getDetailRetained() {
    switch (summaryDepth.round()) {
      case 0:
        return '25%';
      case 1:
        return '50%';
      case 2:
        return '75%';
      case 3:
        return '100%';
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
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'py':
        return Icons.code;
      case 'html':
      case 'htm':
        return Icons.html;
      case 'css':
        return Icons.css;
      case 'js':
        return Icons.javascript;
      case 'json':
        return Icons.data_object;
      case 'xml':
        return Icons.code;
      case 'java':
        return Icons.coffee;
      case 'cpp':
      case 'c':
        return Icons.code;
      case 'swift':
        return Icons.smartphone;
      case 'kt':
        return Icons.android;
      case 'rb':
        return Icons.code;
      case 'php':
        return Icons.php;
      case 'sql':
        return Icons.storage;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
