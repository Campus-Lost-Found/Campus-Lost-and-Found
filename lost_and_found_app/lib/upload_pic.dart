import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const Color _blue = Color(0xFF2563EB);
const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);
const Color _border = Color(0xFFE5E7EB);
const Color _canvas = Color(0xFFF5F7FA);

const int _maxPhotoBytes = 5 * 1024 * 1024;
const List<String> _allowedPhotoExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'webp',
];

class UploadedPhoto {
  const UploadedPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

String? validateUploadedPhoto(String name, int sizeBytes) {
  final extension = name.split('.').last.toLowerCase();
  if (!_allowedPhotoExtensions.contains(extension)) {
    return 'Only JPG, PNG or WEBP images are accepted.';
  }
  if (sizeBytes > _maxPhotoBytes) {
    return 'Photo must be 5 MB or smaller.';
  }
  return null;
}

class UploadPicPage extends StatefulWidget {
  const UploadPicPage({super.key});

  @override
  State<UploadPicPage> createState() => _UploadPicPageState();
}

class _UploadPicPageState extends State<UploadPicPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoName;

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final error = validateUploadedPhoto(picked.name, bytes.length);
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() {
      _photoBytes = bytes;
      _photoName = picked.name;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _upload() {
    final bytes = _photoBytes;
    final name = _photoName;
    if (bytes == null || name == null) {
      _showMessage('Choose an image first.');
      return;
    }
    Navigator.of(context).pop(UploadedPhoto(bytes: bytes, name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Upload Picture'),
        foregroundColor: _ink,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0A111827),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.add_photo_alternate, size: 48, color: _blue),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload a picture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Optional · JPG, PNG or WEBP up to 5 MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 20),
                  if (_photoBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _photoBytes!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _photoName ?? 'Selected picture',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: _ink),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _photoBytes = null;
                            _photoName = null;
                          }),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                        ),
                      ],
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: _muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _upload,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Upload picture'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
