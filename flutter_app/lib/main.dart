import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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
  StreamSubscription? _intentSub;
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();
    _initShareListener();
  }

  void _initShareListener() {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _handleSharedFiles(value);
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedFiles(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    for (final file in files) {
      final url = _extractUrl(file.path);
      if (url != null) {
        setState(() => _sharedUrl = url);
        return;
      }
    }
  }

  String? _extractUrl(String? text) {
    if (text == null) return null;
    final urls = RegExp(r'https?://[^\s]+').allMatches(text);
    return urls.isNotEmpty ? urls.first.group(0) : null;
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
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
