import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class UploadBox extends StatelessWidget {
  const UploadBox({
    super.key,
    required this.file,
    required this.isGenerating,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  final File? file;
  final bool isGenerating;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return InkWell(
      onTap: isGenerating ? null : onPickFile,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFEAF8F1) : const Color(0xFFFAFAFE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasFile ? const Color(0xFFAFE3C8) : const Color(0xFFD4D4DF),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D121828),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: hasFile ? const Color(0xFFD8F3E4) : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFFE5322D),
                size: 34,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? p.basename(file!.path) : 'Upload DOCX File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasFile
                        ? 'File selected. Ready to generate presentation.'
                        : 'Click here to choose your Word .docx file.',
                    style: const TextStyle(
                      color: Color(0xFF777C8E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            if (hasFile)
              IconButton(
                tooltip: 'Remove file',
                onPressed: isGenerating ? null : onRemoveFile,
                icon: const Icon(Icons.close_rounded),
              )
            else
              OutlinedButton.icon(
                onPressed: isGenerating ? null : onPickFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Choose'),
              ),
          ],
        ),
      ),
    );
  }
}