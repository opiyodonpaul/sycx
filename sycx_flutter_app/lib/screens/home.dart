import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/screens/profile.dart';
import 'package:sycx_flutter_app/screens/summary.dart';
import 'package:sycx_flutter_app/widgets/summary_card.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to SycX 🚀'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Profile()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Let\'s summarize your documents!',
              style: TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                SummaryCard(
                  title: 'Upload Document',
                  icon: Icons.upload_file,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Summary()));
                  },
                  summary: null,
                  onView: () {},
                  onDelete: () {},
                  onDownload: () {},
                ),
                SummaryCard(
                  title: 'View Summaries',
                  icon: Icons.view_list,
                  onTap: () {
                    // Navigate to summaries
                  },
                  summary: null,
                  onView: () {},
                  onDelete: () {},
                  onDownload: () {},
                ),
                // Add more cards as needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}
