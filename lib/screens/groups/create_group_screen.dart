import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'course';
  String _privacy = 'private';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final res = await ApiService.post(ApiConfig.groupsManage, {
        'action': 'create',
        'group_name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'group_type': _type,
        'privacy': _privacy,
      });

      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء المجموعة بنجاح')));
        Navigator.pop(context, true); // true to indicate success and trigger reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error']?.toString() ?? 'حدث خطأ')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء مجموعة جديدة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المجموعة *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'course', child: Text('مقرر دراسي')),
                DropdownMenuItem(value: 'department', child: Text('قسم')),
                DropdownMenuItem(value: 'activity', child: Text('نشاط طلابي')),
                DropdownMenuItem(value: 'administrative', child: Text('إدارية')),
              ],
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _privacy,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('عامة (مفتوحة للجميع)')),
                DropdownMenuItem(value: 'private', child: Text('خاصة (تتطلب دعوة أو انضمام)')),
                DropdownMenuItem(value: 'restricted', child: Text('مقيدة')),
              ],
              onChanged: (v) => setState(() => _privacy = v!),
              decoration: const InputDecoration(labelText: 'الخصوصية', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('إنشاء المجموعة'),
            ),
          ],
        ),
      ),
    );
  }
}
