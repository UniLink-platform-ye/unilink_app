import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';
import '../../widgets/server_config_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _idCtrl     = TextEditingController();
  String _role      = 'student';
  String _dept      = 'Computer Science';
  String? _error;
  bool _obscure     = true;

  final _departments = ['Computer Science','Information Systems','IT','Business Administration','Engineering','Medicine','Law','Arts'];
  final _roles       = {'student': 'طالب', 'professor': 'أستاذ'};

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _idCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res  = await auth.register({
      'full_name':   _nameCtrl.text.trim(),
      'email':       _emailCtrl.text.trim(),
      'password':    _passCtrl.text,
      'role':        _role,
      'academic_id': _idCtrl.text.trim(),
      'department':  _dept,
    });
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(emailMasked: res['data']?['email_masked'] ?? _emailCtrl.text.trim()),
      ));
    } else {
      setState(() => _error = res['error'] as String? ?? 'حدث خطأ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'إعدادات السيرفر',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v?.isEmpty??true)?'الاسم مطلوب':null),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'البريد الجامعي *', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => !(v?.contains('@')??false)?'بريد غير صالح':null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'الدور', prefixIcon: Icon(Icons.work_outline)),
                  items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() {
                    _role = v!;
                    // مسح الرقم عند تغيير الدور لتجنب إرسال بيانات خاطئة
                    _idCtrl.clear();
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idCtrl,
                  decoration: InputDecoration(
                    labelText: _role == 'student' ? 'الرقم الجامعي *' : 'الرقم الوظيفي *',
                    prefixIcon: Icon(_role == 'student' ? Icons.badge_outlined : Icons.work_history_outlined),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _dept,
                  decoration: const InputDecoration(labelText: 'القسم', prefixIcon: Icon(Icons.school_outlined)),
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _dept = v!),
                ),
                const SizedBox(height: 12),

                TextFormField(controller: _passCtrl, obscureText: _obscure, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: 'كلمة المرور *', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure?Icons.visibility_outlined:Icons.visibility_off_outlined), onPressed: ()=>setState(()=>_obscure=!_obscure))), validator: (v) => (v?.length??0)<8?'8 أحرف على الأقل':null),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: auth.isLoading ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('إنشاء الحساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
