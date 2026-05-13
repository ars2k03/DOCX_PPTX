import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'license/license_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Process.start(
    'backend/app/dist/main.exe',
    [],
    mode: ProcessStartMode.detached,
  );

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: Size(1180, 820),
      minimumSize: Size(980, 680),
      center: true,
      title: 'A R S Studio',
    );

    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const McqPptDesktopApp());
}

class McqPptDesktopApp extends StatelessWidget {
  const McqPptDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'A R S Studio',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5322D),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        fontFamily: 'Segoe UI',
      ),
      home: const LicenseGate(),
    );
  }
}