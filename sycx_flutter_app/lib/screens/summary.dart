import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/services/summary.dart';
import 'package:sycx_flutter_app/widgets/loading_widget.dart';

class Summary extends StatefulWidget {
  const Summary({super.key});

  @override
  SummaryState createState() => SummaryState();
}

class SummaryState extends State<Summary> {
  bool _loading = false;
  String? _summary;
  String _feedback = '';

  void _uploadDocument() async {
    // Implement document picker
    setState(() {
      _loading = true;
    });

    final summary =
        await Summary.summarizeDocument('user_id', 'document');

    setState(() {
      _loading = false;
      _summary = summary?.summary;
    });
  }

  void _sendFeedback() async {
    setState(() {
      _loading = true;
    });

    await Summary.giveFeedback('summary_id', 'user_id', _feedback);

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Summarization'),
      ),
      body: _loading
          ? const Loading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _summary == null
                      ? ElevatedButton(
                          onPressed: _uploadDocument,
                          child: const Text('Upload Document'),
                        )
                      : Column(
                          children: [
                            const Text('Summary:'),
                            const SizedBox(height: 10),
                            Text(_summary!),
                            TextField(
                              onChanged: (value) => _feedback = value,
                              decoration: const InputDecoration(
                                  labelText: 'Give Feedback'),
                            ),
                            ElevatedButton(
                              onPressed: _sendFeedback,
                              child: const Text('Submit Feedback'),
                            ),
                          ],
                        ),
                ],
              ),
            ),
    );
  }
}
