import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _channel = MethodChannel('com.haris.video_downloader/share');
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();
    _checkForSharedText();
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onNewIntent") {
        final text = call.arguments as String?;
        setState(() => _sharedUrl = _extractUrl(text));
      }
    });
  }

  Future<void> _checkForSharedText() async {
    final text = await _channel.invokeMethod<String>('getSharedText');
    if (text != null && mounted) {
      setState(() => _sharedUrl = _extractUrl(text));
    }
  }

  String? _extractUrl(String? text) {
    if (text == null) return null;
    final urls = RegExp(r'https?://[^\s]+').allMatches(text);
    return urls.isNotEmpty ? urls.first.group(0) : null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: HomeScreen(sharedUrl: _sharedUrl),
    );
  }
}
