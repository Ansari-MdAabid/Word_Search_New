// main.dart - Updated to use EnhancedSplashScreen

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'services/sound_manager.dart';
import 'screens/splash_screen.dart';
import 'package:flutter/services.dart';


void main() async {
  // Ensure binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Use runZonedGuarded to catch global unhandled exceptions
  runZonedGuarded(() async {
    try {
      // Initialize storage first
      await GetStorage.init();
      
      // Initialize sound manager early to avoid race conditions
      await SoundManager().init();
      
      runApp(WordSearchApp());
    } catch (e, stack) {
      print('CRITICAL: Initialization error: $e\n$stack');
      // In a real app, you might want to show a fallback UI here
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Failed to initialize app: $e'),
            ),
          ),
        )
      );
    }
  }, (error, stack) {
    print('CRITICAL: Unhandled error in root zone: $error\n$stack');
  });
}

class WordSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Word Search: Evolution',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const EnhancedSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}