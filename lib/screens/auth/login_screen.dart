import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _obscure   = true;
  String? _error;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res  = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(emailMasked: res['data']?['email_masked'] ?? ''),
      ));
    } else {
      final err = res['error'] as String? ?? 'حدث خطأ';
      setState(() => _error = err);
      _showUnverifiedResend = err.contains('غير مفعّل') || err.contains('تفعيله');
    }
  }

  bool _showUnverifiedResend = false;

  Future<void> _resendVerification() async {
    if (_email.text.isEmpty || _password.text.isEmpty) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res = await auth.resendOtp(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _showUnverifiedResend = false);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(emailMasked: res['data']?['email_masked'] ?? ''),
      ));
    } else {
      setState(() => _error = res['error'] as String? ?? 'فشل إرسال الرمز');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Logo
                Center(
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Secure Uni Network', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E3A5F))),
                const Text('سجّل دخولك للمنصة الأكاديمية الموثوقة', textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                const SizedBox(height: 40),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                    ]),
                  ),
                  if (_showUnverifiedResend) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _resendVerification,
                      icon: const Icon(Icons.email_outlined, size: 20),
                      label: const Text('إعادة إرسال رمز التفعيل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                ],

                // Email
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? 'أدخل بريدك الإلكتروني' : null,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v?.length ?? 0) < 6 ? 'كلمة المرور قصيرة' : null,
                ),
                const SizedBox(height: 24),

                // Submit
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('تسجيل الدخول'),
                ),
                const SizedBox(height: 16),

                // Register Link
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('ليس لديك حساب؟ سجّل الآن', style: TextStyle(color: Color(0xFF2563EB))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
