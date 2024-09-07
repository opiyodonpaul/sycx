import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/widgets/custom_app_bar_mini.dart';
import 'package:sycx_flutter_app/widgets/custom_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewSummary extends StatelessWidget {
  final Map<String, dynamic> summary;

  const ViewSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarMini(title: summary['title'] ?? 'View Summary'),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary['title'] ?? 'Untitled Summary',
                  style: AppTextStyles.headingStyleNoShadow.copyWith(
                    color: AppColors.primaryTextColorDark,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Introduction',
                  summary['introduction'] ?? 'No introduction available.',
                ),
                _buildImage(summary['image'] ??
                    'https://source.unsplash.com/random/800x400?machine+learning'),
                _buildSection(
                  'Key Concepts',
                  'Machine learning is a subset of artificial intelligence that focuses on the development of algorithms and statistical models that enable computer systems to improve their performance on a specific task through experience.',
                ),
                _buildSubSection(
                  'Types of Machine Learning',
                  [
                    'Supervised Learning',
                    'Unsupervised Learning',
                    'Reinforcement Learning',
                  ],
                ),
                _buildTable(),
                _buildSection(
                  'Applications',
                  'Machine learning has a wide range of applications across various industries:',
                ),
                _buildList([
                  'Healthcare: Disease prediction and diagnosis',
                  'Finance: Fraud detection and risk assessment',
                  'E-commerce: Recommendation systems',
                  'Autonomous vehicles: Self-driving cars',
                  'Natural Language Processing: Language translation and sentiment analysis',
                ]),
                _buildImage(
                    'https://plus.unsplash.com/premium_photo-1683121710572-7723bd2e235d?q=80&w=1632&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                _buildSection(
                  'Recent Advancements',
                  'The field of machine learning is rapidly evolving. Some recent advancements include:',
                ),
                _buildSubSection(
                  'Transformer Models',
                  [
                    'GPT (Generative Pre-trained Transformer)',
                    'BERT (Bidirectional Encoder Representations from Transformers)',
                  ],
                ),
                _buildLink(
                  'Learn more about Transformer models',
                  'https://arxiv.org/abs/1706.03762',
                ),
                _buildSection(
                  'Challenges and Future Directions',
                  'Despite its progress, machine learning faces several challenges:',
                ),
                _buildList([
                  'Ethical considerations and bias in AI',
                  'Interpretability and explainability of complex models',
                  'Data privacy and security concerns',
                  'Computational resources and energy consumption',
                ]),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: 'home',
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.primaryTextColorDark,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.subheadingStyle.copyWith(
            color: AppColors.primaryTextColorDark,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $item',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.primaryTextColorDark,
                ),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        Table(
          border: TableBorder.all(color: AppColors.textFieldBorderColor),
          children: [
            TableRow(
              decoration:
                  const BoxDecoration(color: AppColors.primaryButtonColor),
              children: [
                _buildTableCell('Algorithm', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Use Case', isHeader: true),
              ],
            ),
            TableRow(
              children: [
                _buildTableCell('Linear Regression'),
                _buildTableCell('Supervised'),
                _buildTableCell('Prediction'),
              ],
            ),
            TableRow(
              children: [
                _buildTableCell('K-Means'),
                _buildTableCell('Unsupervised'),
                _buildTableCell('Clustering'),
              ],
            ),
            TableRow(
              children: [
                _buildTableCell('Random Forest'),
                _buildTableCell('Supervised'),
                _buildTableCell('Classification'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: isHeader
            ? AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.primaryButtonTextColor,
                fontWeight: FontWeight.bold,
              )
            : AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.primaryTextColorDark,
              ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                '• $item',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.primaryTextColorDark,
                ),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLink(String text, String url) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _launchURL(url),
          child: Text(
            text,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.primaryButtonColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }
}
