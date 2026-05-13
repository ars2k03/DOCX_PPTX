import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';
import '../license/expired_screen.dart';
import '../license/license_service.dart';
import '../services/ppt_api_service.dart';
import '../widgets/generator_panel.dart';

class GeneratorHomePage extends StatefulWidget {
  const GeneratorHomePage({super.key});

  @override
  State<GeneratorHomePage> createState() => _GeneratorHomePageState();
}

class _GeneratorHomePageState extends State<GeneratorHomePage> {
  final PptApiService apiService = PptApiService();
  final LicenseService licenseService = LicenseService();

  File? selectedFile;

  bool isGenerating = false;
  double progress = 0;
  String progressLabel = 'Ready';
  String? message;
  bool messageIsError = false;

  Duration? remainingLicenseDuration;

  Timer? progressTimer;
  Timer? licenseTimer;

  @override
  void initState() {
    super.initState();
    startLiveLicenseTimer();
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    licenseTimer?.cancel();
    super.dispose();
  }

  Future<void> startLiveLicenseTimer() async {
    await updateRemainingLicenseTime();

    licenseTimer?.cancel();

    licenseTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) async {
        await updateRemainingLicenseTime();
      },
    );
  }

  Future<void> updateRemainingLicenseTime() async {
    final duration = await licenseService.remainingDuration();

    if (!mounted) return;

    if (duration == null) {
      return;
    }

    if (duration <= Duration.zero) {
      licenseTimer?.cancel();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LicenseExpiredPage(),
        ),
            (_) => false,
      );

      return;
    }

    setState(() {
      remainingLicenseDuration = duration;
    });
  }

  Future<void> pickFile() async {
    if (isGenerating) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: false,
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final error = await validateFile(file);

    if (error != null) {
      showMessage(error, isError: true);
      return;
    }

    setState(() {
      selectedFile = file;
      progress = 0;
      progressLabel = 'Ready';
      message = 'DOCX file selected.';
      messageIsError = false;
    });
  }

  Future<String?> validateFile(File file) async {
    if (!file.path.toLowerCase().endsWith('.docx')) {
      return 'Only .docx Word files are accepted.';
    }

    final bytes = await file.length();

    if (bytes <= 0) {
      return 'Selected file is empty.';
    }

    if (bytes > maxFileMb * 1024 * 1024) {
      return 'File must be under $maxFileMb MB.';
    }

    return null;
  }

  bool validateForm() {
    if (selectedFile == null) {
      showMessage('Please upload a DOCX file first.', isError: true);
      return false;
    }

    return true;
  }

  Future<void> generatePresentation() async {
    if (isGenerating || !validateForm()) return;

    try {
      setGenerating(true);
      startFakeProgress();

      final bytes = await apiService.generatePpt(
        file: selectedFile!,
      );

      completeProgress();

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save generated PPTX',
        fileName: defaultOutputName(),
        type: FileType.custom,
        allowedExtensions: ['pptx'],
        bytes: bytes,
      );

      if (outputPath == null) {
        showMessage('PPTX generated, but save was cancelled.');
        return;
      }

      if (!Platform.isMacOS) {
        final output = File(outputPath);

        if (!await output.exists() || await output.length() == 0) {
          await output.writeAsBytes(bytes, flush: true);
        }
      }

      showMessage(
        'Presentation saved successfully: ${p.basename(outputPath)}',
      );
    } catch (error) {
      progressTimer?.cancel();

      setState(() {
        progress = 0;
        progressLabel = 'Failed';
      });

      showMessage(apiService.friendlyError(error), isError: true);
    } finally {
      setGenerating(false);
    }
  }

  void setGenerating(bool value) {
    setState(() {
      isGenerating = value;

      if (!value && progress == 100) {
        progressLabel = 'Complete ✓';
      }
    });
  }

  void startFakeProgress() {
    progressTimer?.cancel();

    setState(() {
      progress = 4;
      progressLabel = 'Uploading DOCX…';
      message = null;
      messageIsError = false;
    });

    progressTimer = Timer.periodic(
      const Duration(milliseconds: 420),
          (_) {
        if (!mounted) return;

        setState(() {
          if (progress < 28) {
            progress += 9;
            progressLabel = 'Parsing MCQs…';
          } else if (progress < 58) {
            progress += 6;
            progressLabel = 'Loading template…';
          } else if (progress < 84) {
            progress += 4;
            progressLabel = 'Generating slides…';
          } else {
            progress = 87;
            progressLabel = 'Finalising PPTX…';
          }
        });
      },
    );
  }

  void completeProgress() {
    progressTimer?.cancel();

    setState(() {
      progress = 100;
      progressLabel = 'Complete ✓';
    });
  }

  void showMessage(String text, {bool isError = false}) {
    setState(() {
      message = text;
      messageIsError = isError;
    });
  }

  void removeFile() {
    if (isGenerating) return;

    setState(() {
      selectedFile = null;
      progress = 0;
      progressLabel = 'Ready';
      message = null;
      messageIsError = false;
    });
  }

  String defaultOutputName() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'MCQ_Presentation_$date.pptx';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: GeneratorPanel(
            selectedFile: selectedFile,
            isGenerating: isGenerating,
            progress: progress,
            progressLabel: progressLabel,
            message: message,
            messageIsError: messageIsError,
            remainingLicenseDuration: remainingLicenseDuration,
            onPickFile: pickFile,
            onRemoveFile: removeFile,
            onGenerate: generatePresentation,
          ),
        ),
      ),
    );
  }
}