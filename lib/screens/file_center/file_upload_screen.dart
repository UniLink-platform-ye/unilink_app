import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  File? _file;
  bool _uploading = false;

  String _category = 'lecture';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;
    setState(() => _file = File(path));
  }

  Future<void> _upload() async {
    if (_file == null || _uploading) return;
    setState(() => _uploading = true);
    try {
      final fields = <String, String>{
        'category': _category,
        if (_titleCtrl.text.trim().isNotEmpty) 'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      };
      final r = await ApiService.postMultipart(
        ApiConfig.files,
        file: _file!,
        fields: fields,
      );
      if (!mounted) return;
      if (r['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الملف بنجاح')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'فشل رفع الملف')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر رفع الملف')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _file?.path.split(Platform.pathSeparator).last;
    return Scaffold(
      appBar: AppBar(title: const Text('رفع ملف')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.attach_file)),
              title: Text(fileName ?? 'اختر ملفًا'),
              subtitle: Text(_file == null ? 'PDF/صور/عروض/ملفات مضغوطة/فيديو (حتى 100MB)' : _file!.path),
              trailing: OutlinedButton(onPressed: _pickFile, child: const Text('اختيار')),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _category,
            items: const [
              DropdownMenuItem(value: 'lecture', child: Text('محاضرة')),
              DropdownMenuItem(value: 'assignment', child: Text('واجب')),
              DropdownMenuItem(value: 'reference', child: Text('مرجع')),
              DropdownMenuItem(value: 'other', child: Text('أخرى')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'lecture'),
            decoration: const InputDecoration(labelText: 'تصنيف الملف', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'عنوان (اختياري)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'وصف (اختياري)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (_file == null || _uploading) ? null : _upload,
            icon: _uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload),
            label: Text(_uploading ? 'جارٍ الرفع...' : 'رفع'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}

