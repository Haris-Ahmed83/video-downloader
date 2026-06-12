import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../config.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.backendUrl,
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<String> startDownload(String url) async {
    final res = await _dio.post('/api/download', data: {'url': url});
    return res.data['task_id'] as String;
  }

  Future<Map<String, dynamic>> getStatus(String taskId) async {
    final res = await _dio.get('/api/status/$taskId');
    return res.data as Map<String, dynamic>;
  }

  Future<File> downloadVideo(String taskId) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$taskId.mp4';
    await _dio.download('/api/video/$taskId', filePath);
    return File(filePath);
  }
}
