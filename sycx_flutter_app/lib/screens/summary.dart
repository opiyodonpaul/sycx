import 'package:flutter/material.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/summary.dart';
import 'package:sycx_flutter_app/widgets/loading.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  bool _loading = false;
  Summary? _summary;
  String _feedback = '';

  void _uploadDocument() async {
    // Implement document picker
    setState(() {
      _loading = true;
    });

    try {
      final summary =
          await SummaryService.summarizeDocument('user_id', 'document');

      setState(() {
        _loading = false;
        _summary = summary;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
      ));
    }
  }

  void _sendFeedback() async {
    if (_summary == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await SummaryService.giveFeedback(_summary!.id, 'user_id', _feedback);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Feedback sent successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
      ));
    } finally {
      setState(() {
        _loading = false;
      });
    }
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
                            Text(_summary!.summaryText),
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
