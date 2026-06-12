import 'package:gal/gal.dart';
import 'api_service.dart';

class DownloadService {
  final ApiService _api;
  final void Function(String message) onStatus;

  DownloadService({required this.onStatus}) : _api = ApiService();

  Future<void> processUrl(String url) async {
    onStatus('Starting download...');
    final taskId = await _api.startDownload(url);

    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await _api.getStatus(taskId);

      if (status['status'] == 'completed') {
        onStatus('Download complete! Saving to gallery...');
        final file = await _api.downloadVideo(taskId);
        await Gal.putVideo(file.path);
        onStatus('Saved to gallery!');
        return;
      }

      if (status['status'] == 'error') {
        onStatus('Error: ${status['error']}');
        return;
      }

      onStatus('Downloading...');
    }
  }
}
