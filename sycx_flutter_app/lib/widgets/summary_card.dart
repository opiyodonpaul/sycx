import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/models/summary.dart';

class SummaryCard extends StatelessWidget {
  final Summary summary;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.onView,
    required this.onDelete,
    required this.onDownload,
    required String title,
    required IconData icon,
    required Null Function() onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary.summaryText.length > 100
                ? '${summary.summaryText.substring(0, 100)}...'
                : summary.summaryText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                color: Colors.blueAccent,
                onPressed: onView,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                color: Colors.green,
                onPressed: onDownload,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.redAccent,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
