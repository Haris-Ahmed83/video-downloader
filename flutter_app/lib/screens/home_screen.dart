import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String? sharedUrl;
  const HomeScreen({super.key, this.sharedUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final NotificationService _notif = NotificationService();
  String _status = '';
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _notif.init();
    if (widget.sharedUrl != null && widget.sharedUrl!.isNotEmpty) {
      _urlController.text = widget.sharedUrl!;
      _startDownload(widget.sharedUrl!);
    }
  }

  Future<void> _startDownload(String url) async {
    setState(() { _downloading = true; _status = ''; });
    final service = DownloadService(
      onStatus: (msg) {
        setState(() => _status = msg);
        if (msg == 'Saved to gallery!') {
          _notif.show('Video Saved', 'Video has been saved to your gallery');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _downloading = false);
          });
        }
      },
    );
    try {
      await service.processUrl(url.trim());
    } catch (e) {
      setState(() { _status = 'Failed: $e'; _downloading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Downloader')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Paste Instagram/TikTok URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloading || _urlController.text.isEmpty
                  ? null
                  : () => _startDownload(_urlController.text),
              child: const Text('Download'),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_status.contains('Saved') || _status.contains('Error'))
                        Icon(
                          _status.contains('Saved') ? Icons.check_circle : Icons.error,
                          color: _status.contains('Saved') ? Colors.green : Colors.red,
                        )
                      else
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_status)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
