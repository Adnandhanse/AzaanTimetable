import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/masjid.dart';
import 'admin_dashboard_screen.dart';

class UploadVerificationScreen extends StatefulWidget {
  final Masjid masjid;
  const UploadVerificationScreen({super.key, required this.masjid});

  @override
  State<UploadVerificationScreen> createState() => _UploadVerificationScreenState();
}

class _UploadVerificationScreenState extends State<UploadVerificationScreen> {
  String? _fileName;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileName = result.files.first.name;
        widget.masjid.verificationDocName = _fileName;
      });
    }
  }

  void _finish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submitted. Status: Pending Verification.'),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminDashboardScreen(managedMasjids: [widget.masjid]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Verification'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To activate your masjid, please upload one proof document:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Masjid certificate\n• Imam ID\n• Committee letter',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Choose Document'),
              onPressed: _pickDocument,
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFFFFF7ED),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Until the platform team reviews and verifies this document, '
                        'you will not be able to change prayer times.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                onPressed: _fileName == null ? null : _finish,
                child: const Text('Submit for Review', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
