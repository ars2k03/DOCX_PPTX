import 'dart:io';

import 'package:flutter/material.dart';

import 'upload_box.dart';

class GeneratorPanel extends StatelessWidget {
  const GeneratorPanel({
    super.key,
    required this.selectedFile,
    required this.isGenerating,
    required this.progress,
    required this.progressLabel,
    required this.message,
    required this.messageIsError,
    required this.remainingLicenseDuration,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onGenerate,
  });

  final File? selectedFile;
  final bool isGenerating;
  final double progress;
  final String progressLabel;
  final String? message;
  final bool messageIsError;
  final Duration? remainingLicenseDuration;

  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final canGenerate = selectedFile != null && !isGenerating;

    return Container(
      width: 760,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE0E0EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15121828),
            blurRadius: 42,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GeneratorHeader(
            remainingLicenseDuration: remainingLicenseDuration,
          ),
          const SizedBox(height: 26),

          UploadBox(
            file: selectedFile,
            isGenerating: isGenerating,
            onPickFile: onPickFile,
            onRemoveFile: onRemoveFile,
          ),

          if (isGenerating || progress > 0) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progressLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171827),
                    ),
                  ),
                ),
                Text(
                  '${progress.round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress / 100,
                backgroundColor: const Color(0xFFEDEDF5),
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: canGenerate ? onGenerate : null,
              icon: Icon(
                isGenerating
                    ? Icons.hourglass_top_rounded
                    : Icons.auto_awesome_rounded,
              ),
              label: Text(
                isGenerating ? 'Generating PPT…' : 'Generate',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          if (message != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: messageIsError
                    ? const Color(0xFFFFEFEF)
                    : const Color(0xFFEAF8F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: messageIsError
                      ? const Color(0xFFFFC4C4)
                      : const Color(0xFFBDEBCD),
                ),
              ),
              child: Text(
                message!,
                style: TextStyle(
                  color: messageIsError
                      ? const Color(0xFFE5322D)
                      : const Color(0xFF119C64),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GeneratorHeader extends StatelessWidget {
  const _GeneratorHeader({
    required this.remainingLicenseDuration,
  });

  final Duration? remainingLicenseDuration;

  String formatRemainingTime(Duration duration) {
    final totalSeconds = duration.inSeconds;

    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '$days Day $hours hr $minutes min $seconds sec';
  }

  @override
  Widget build(BuildContext context) {
    final duration = remainingLicenseDuration;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.slideshow_rounded,
          color: Color(0xFFE5322D),
          size: 34,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOCX to PPT Generator',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF171827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Upload your MCQ DOCX file and generate a professional PowerPoint.',
                style: TextStyle(
                  color: Color(0xFF777C8E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFD4D1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: Color(0xFFE5322D),
              ),
              const SizedBox(width: 8),
              Text(
                duration == null
                    ? 'Checking access...'
                    : formatRemainingTime(duration),
                style: const TextStyle(
                  color: Color(0xFFE5322D),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}