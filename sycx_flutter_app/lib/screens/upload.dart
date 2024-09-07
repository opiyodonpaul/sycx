import 'package:flutter/material.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  UploadState createState() => UploadState();
}

class UploadState extends State<Upload> {
  List<String> uploadedFiles = [];
  String selectedSummaryType = 'Brief Summary';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Drag & Drop or Click to Upload',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Upload Files'),
              onPressed: () {
                // TODO: Implement file upload
                setState(() {
                  uploadedFiles.add('Document${uploadedFiles.length + 1}.pdf');
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Preview Content',
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uploadedFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(uploadedFiles[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        uploadedFiles.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Summarization Preferences',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio(
                  value: 'Brief Summary',
                  groupValue: selectedSummaryType,
                  onChanged: (value) {
                    setState(() {
                      selectedSummaryType = value.toString();
                    });
                  },
                ),
                const Text('Brief Summary'),
                const SizedBox(width: 16),
                Radio(
                  value: 'Detailed Summary',
                  groupValue: selectedSummaryType,
                  onChanged: (value) {
                    setState(() {
                      selectedSummaryType = value.toString();
                    });
                  },
                ),
                const Text('Detailed Summary'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        // TODO: Implement navigation
      },
    );
  }
}
