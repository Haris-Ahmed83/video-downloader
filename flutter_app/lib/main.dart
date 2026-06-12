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
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();
    _initShareListener();
  }

  void _initShareListener() {
    ReceiveSharingIntent.instance.getTextStream().listen((text) {
      setState(() => _sharedUrl = _extractUrl(text));
    });
    ReceiveSharingIntent.instance.getInitialText().then((text) {
      setState(() => _sharedUrl = _extractUrl(text));
    });
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
