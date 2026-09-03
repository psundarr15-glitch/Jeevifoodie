import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme.dart';

/// A labeled upload slot: shows a thumbnail (if it's an image) or the
/// filename (if it's a document), with a button to pick/replace it.
/// [isImage] controls which picker opens - true uses the camera/gallery
/// picker (for photos, banners, logos), false opens a general file
/// picker (for certificates/ID proofs/RC documents, which are often PDFs).
class FilePickerField extends StatefulWidget {
  final String label;
  final String? helperText;
  final bool isImage;
  final bool required;
  final ValueChanged<File?> onChanged;

  const FilePickerField({
    super.key,
    required this.label,
    required this.onChanged,
    this.helperText,
    this.isImage = true,
    this.required = false,
  });

  @override
  State<FilePickerField> createState() => _FilePickerFieldState();
}

class _FilePickerFieldState extends State<FilePickerField> {
  File? _file;

  Future<void> _pick() async {
    if (widget.isImage) {
      final picked = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () async {
                  final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (context.mounted) Navigator.of(context).pop(x);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (context.mounted) Navigator.of(context).pop(x);
                },
              ),
            ],
          ),
        ),
      );
      if (picked != null) {
        setState(() => _file = File(picked.path));
        widget.onChanged(_file);
      }
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        setState(() => _file = File(result.files.single.path!));
        widget.onChanged(_file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: widget.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              children: widget.required ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : null,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_file != null && widget.isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_file!, width: 44, height: 44, fit: BoxFit.cover),
                    )
                  else
                    Icon(widget.isImage ? Icons.image_outlined : Icons.description_outlined, color: Colors.grey.shade500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _file == null ? 'Tap to upload' : _file!.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _file == null ? Colors.grey.shade600 : AppTheme.textPrimary(context), fontSize: 13),
                    ),
                  ),
                  Icon(_file == null ? Icons.upload_outlined : Icons.check_circle, color: _file == null ? Colors.grey : AppTheme.primary, size: 20),
                ],
              ),
            ),
          ),
          if (widget.helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.helperText!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}
