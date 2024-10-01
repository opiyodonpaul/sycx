import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/services/summary.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/animated_button.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:sycx_flutter_app/widgets/padded_round_slider_value_indicator_shape.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  UploadState createState() => UploadState();
}

class UploadState extends State<Upload> with TickerProviderStateMixin {
  String? currentUserId;
  List<PlatformFile> uploadedFiles = [];
  double summaryDepth = 0;
  bool isLoading = false;
  late AnimationController _animationController;
  late AnimationController _loadingAnimationController;
  late AnimationController _deleteAnimationController;
  late AnimationController _previewAnimationController;
  double _progress = 0.0;
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Swahili',
    'Spanish',
    'French',
    'German',
    'Chinese',
  ];
  final String _currentStepName = '';
  PlatformFile? _previewFile;
  bool _mergeSummaries = false;
  dynamic _filePreviewContent;
  int _totalSteps = 0;
  int _currentStep = 0;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  PdfViewerController? _pdfViewerController;

  int _currentPdfPage = 1;
  int _totalPdfPages = 0;

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
    _previewAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    _pdfViewerController = PdfViewerController();
    // Get the current user's ID
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    CustomBottomNavBar.updateLastMainRoute('/upload');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingAnimationController.dispose();
    _deleteAnimationController.dispose();
    _previewAnimationController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    _pdfViewerController?.dispose();
    super.dispose();
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'gif', 'bmp'],
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

    if (currentUserId == null) {
      Fluttertoast.showToast(
        msg: "User not logged in",
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
      List<Map<String, dynamic>> documents = [];
      for (var file in uploadedFiles) {
        final bytes = await File(file.path!).readAsBytes();
        final base64Content = base64Encode(bytes);
        documents.add({
          'name': file.name,
          'content': base64Content,
          'type': file.extension,
        });
      }

      final summaryResult = await SummaryService.summarizeDocuments(
        currentUserId!,
        documents,
        _mergeSummaries,
        summaryDepth,
        _selectedLanguage,
        (progress) {
          setState(() {
            _progress = progress;
            _currentStep = (_totalSteps * progress).round();
          });
        },
      );

      setState(() {
        isLoading = false;
      });
      _loadingAnimationController.reverse();

      Navigator.pushNamed(context, '/summaries', arguments: summaryResult);
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

  Future<void> _loadFilePreview(PlatformFile file) async {
    setState(() {
      _filePreviewContent = null;
      _currentPdfPage = 1;
      _totalPdfPages = 0;
    });

    switch (file.extension?.toLowerCase()) {
      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'html':
      case 'css':
      case 'js':
      case 'py':
      case 'java':
      case 'cpp':
      case 'c':
      case 'swift':
      case 'kt':
      case 'rb':
      case 'php':
      case 'sql':
        final content = await File(file.path!).readAsString();
        setState(() {
          _filePreviewContent = content;
        });
        break;
      case 'pdf':
        setState(() {
          _filePreviewContent = 'pdf';
        });
        break;
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
        setState(() {
          _filePreviewContent =
              "Preview not available for this file type. Please use a specialized viewer.";
        });
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        setState(() {
          _filePreviewContent = File(file.path!);
        });
        break;
      case 'svg':
        final content = await File(file.path!).readAsString();
        setState(() {
          _filePreviewContent = content;
        });
        break;
      case 'mp4':
      case 'mov':
      case 'avi':
        _videoPlayerController = VideoPlayerController.file(File(file.path!));
        await _videoPlayerController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
        );
        setState(() {
          _filePreviewContent = _chewieController;
        });
        break;
      case 'mp3':
      case 'wav':
      case 'ogg':
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setSource(DeviceFileSource(file.path!));
        setState(() {
          _filePreviewContent = _audioPlayer;
        });
        break;
      case 'zip':
      case 'rar':
      case '7z':
        setState(() {
          _filePreviewContent =
              "Preview not available for compressed files. Please extract the contents to view.";
        });
        break;
      default:
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

  Widget _buildPreviewOverlay() {
    final size = MediaQuery.of(context).size;
    final previewHeight = size.height * 0.78;
    final previewWidth = size.width * 0.98;

    return AnimatedBuilder(
      animation: _previewAnimationController,
      builder: (context, child) {
        return Positioned(
          top: (size.height - previewHeight) / 2,
          left: (size.width - previewWidth) / 2,
          child: GestureDetector(
            onTap: () {
              _previewAnimationController.reverse().then((_) {
                setState(() {
                  _previewFile = null;
                  _filePreviewContent = null;
                });
              });
            },
            child: AnimatedOpacity(
              opacity: _previewAnimationController.value,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: previewWidth,
                      height: previewHeight,
                      decoration: BoxDecoration(
                        color: AppColors.textFieldFillColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Preview: ${_previewFile!.name}',
                                    style: AppTextStyles.titleStyle.copyWith(
                                        color: AppColors.primaryTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryButtonColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: AppColors.primaryTextColor),
                                    onPressed: () {
                                      _previewAnimationController
                                          .reverse()
                                          .then((_) {
                                        setState(() {
                                          _previewFile = null;
                                          _filePreviewContent = null;
                                        });
                                      });
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildPreviewContent(
                                previewWidth, previewHeight - 60),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewContent(double width, double height) {
    if (_filePreviewContent == null) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(
              height: 20,
            ),
            Text(
              'Preview content is null',
              style: TextStyle(
                color: AppColors.primaryTextColor,
                fontSize: 20,
              ),
            ),
          ],
        ),
      );
    }

    if (_filePreviewContent == 'pdf') {
      return Column(
        children: [
          Expanded(
            child: SfPdfViewer.file(
              File(_previewFile!.path!),
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPdfPages = details.document.pages.count;
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPdfPage = details.newPageNumber;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPdfPage > 1
                    ? () => _pdfViewerController?.previousPage()
                    : null,
              ),
              Text('$_currentPdfPage / $_totalPdfPages'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentPdfPage < _totalPdfPages
                    ? () => _pdfViewerController?.nextPage()
                    : null,
              ),
            ],
          ),
        ],
      );
    }

    if (_filePreviewContent is String) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _filePreviewContent as String,
            style: AppTextStyles.bodyTextStyle,
          ),
        ),
      );
    } else if (_filePreviewContent is File) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Image.file(
          _filePreviewContent as File,
          fit: BoxFit.contain,
        ),
      );
    } else if (_filePreviewContent is ChewieController) {
      return Chewie(controller: _filePreviewContent as ChewieController);
    } else if (_filePreviewContent is AudioPlayer) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_filePreviewContent.state == PlayerState.playing
                  ? Icons.pause
                  : Icons.play_arrow),
              onPressed: () {
                if (_filePreviewContent.state == PlayerState.playing) {
                  _filePreviewContent.pause();
                } else {
                  _filePreviewContent.resume();
                }
                setState(() {});
              },
            ),
            Text('Audio Player', style: AppTextStyles.bodyTextStyle),
          ],
        ),
      );
    } else if (_previewFile!.extension?.toLowerCase() == 'svg') {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: SvgPicture.string(
          _filePreviewContent as String,
          fit: BoxFit.contain,
        ),
      );
    } else if (_filePreviewContent is Image) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: _filePreviewContent,
      );
    } else {
      return Center(
        child: Text(
          "Preview not available for this file type.",
          style: AppTextStyles.bodyTextStyle,
        ),
      );
    }
  }

  Widget _buildUploadedFiles() {
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
                'Uploaded Files (${uploadedFiles.length} files)',
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
                            _previewAnimationController.forward();
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
                _buildUploadedFiles(),
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.gradientStart, size: 34),
                  const SizedBox(width: 12),
                  Text(
                    'How to use:',
                    style: AppTextStyles.titleStyle.copyWith(
                      color: AppColors.primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _buildInstructionStep('1', 'Upload files',
                      'Tap "Upload" and select documents.'),
                  _buildInstructionStep(
                      '2', 'Preview', 'Tap file cards to view contents.'),
                  _buildInstructionStep(
                      '3', 'Manage', 'Remove files using the delete icon.'),
                  _buildInstructionStep(
                      '4', 'Clear all', 'Use "Clear All" to remove all files.'),
                  _buildInstructionStep(
                      '5', 'Set depth', 'Adjust slider for summary detail.'),
                  _buildInstructionStep(
                      '6', 'Language', 'Choose output language from dropdown.'),
                  _buildInstructionStep(
                      '7', 'Merge', 'Choose to combine or separate summaries.'),
                  _buildInstructionStep(
                      '8', 'Generate', 'Tap "Summarize" to process files.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
      String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
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
