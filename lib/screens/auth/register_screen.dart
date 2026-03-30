import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';
import '../../widgets/server_config_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _idCtrl    = TextEditingController();
  String _role     = 'student';
  String _dept     = 'Computer Science';
  String? _error;
  bool _obscure    = true;

  final _departments = [
    'Computer Science', 'Information Systems', 'IT',
    'Business Administration', 'Engineering', 'Medicine', 'Law', 'Arts',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _idCtrl.dispose();
    super.dispose();
  }

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
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final roles = {
      'student':   l10n.studentRole,
      'professor': l10n.professorRole,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.serverSettings,
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
                // ── خطأ ──────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        cs.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: cs.error.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: cs.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── الاسم الكامل ──────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText:  '${l10n.fullNameLabel} *',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? l10n.nameRequired : null,
                ),
                const SizedBox(height: 12),

                // ── البريد الجامعي ────────────────────────────────
                TextFormField(
                  controller:   _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText:  '${l10n.universityEmail} *',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => !(v?.contains('@') ?? false) ? l10n.invalidEmail : null,
                ),
                const SizedBox(height: 12),

                // ── الدور ────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText:  l10n.roleLabel,
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  dropdownColor: cs.surface,
                  items: roles.entries.map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() { _role = v!; _idCtrl.clear(); }),
                ),
                const SizedBox(height: 12),

                // ── الرقم الجامعي/الوظيفي ─────────────────────────
                TextFormField(
                  controller: _idCtrl,
                  decoration: InputDecoration(
                    labelText:  _role == 'student'
                        ? '${l10n.academicIdLabel} *'
                        : '${l10n.employeeIdLabel} *',
                    prefixIcon: Icon(_role == 'student'
                        ? Icons.badge_outlined
                        : Icons.work_history_outlined),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),

                // ── القسم ────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _dept,
                  decoration: InputDecoration(
                    labelText:  l10n.departmentLabel,
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  dropdownColor: cs.surface,
                  items: _departments.map((d) =>
                      DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _dept = v!),
                ),
                const SizedBox(height: 12),

                // ── كلمة المرور ───────────────────────────────────
                TextFormField(
                  controller:  _passCtrl,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText:  '${l10n.passwordLabel} *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v?.length ?? 0) < 8 ? l10n.passwordTooShort : null,
                ),
                const SizedBox(height: 24),

                // ── زر الإنشاء ───────────────────────────────────
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.createAccountButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
