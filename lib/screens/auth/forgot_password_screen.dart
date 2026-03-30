// lib/screens/auth/forgot_password_screen.dart
// شاشة نسيت كلمة المرور — 3 مراحل — Dark Mode + L10n

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;

  final _emailCtrl       = TextEditingController();
  final _otpCtrl         = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String? _error;
  String  _emailMasked = '';

  @override
  void dispose() {
    _emailCtrl.dispose(); _otpCtrl.dispose();
    _passCtrl.dispose();  _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res  = await auth.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _emailMasked = res['data']?['email_masked'] ?? _emailCtrl.text;
        _step = 2;
      });
    } else {
      setState(() => _error = res['error'] as String? ?? 'حدث خطأ');
    }
  }

  void _submitOtp() {
    if (!_formKey2.currentState!.validate()) return;
    setState(() { _error = null; _step = 3; });
  }

  Future<void> _submitReset() async {
    if (!_formKey3.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res  = await auth.resetPassword(
      otp:             _otpCtrl.text.trim(),
      newPassword:     _passCtrl.text,
      confirmPassword: _confirmPassCtrl.text,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      _showSuccess();
    } else {
      setState(() => _error = res['error'] as String? ?? 'فشل تغيير كلمة المرور');
      if (_error!.contains('انتهت')) setState(() => _step = 1);
    }
  }

  void _showSuccess() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: cs.surface,
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color:        Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 42, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(l10n.passwordSuccessTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(l10n.passwordSuccessMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.65), fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.signInButton),
              ),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final titles   = [l10n.step1Title,    l10n.step2Title,              l10n.step3Title];
    final subtitles = [l10n.step1Subtitle, l10n.step2Subtitle(_emailMasked), l10n.step3Subtitle];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(currentStep: _step, primaryColor: cs.primary),
              const SizedBox(height: 32),

              // ── Header ──────────────────────────────────────────
              Text(titles[_step - 1],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 6),
              Text(subtitles[_step - 1],
                style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 14)),
              const SizedBox(height: 28),

              // ── خطأ ─────────────────────────────────────────────
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

              // ── محتوى الخطوة ────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 1
                      ? _buildStep1(auth, cs, l10n)
                      : _step == 2
                          ? _buildStep2(auth, cs, l10n)
                          : _buildStep3(auth, cs, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(AuthProvider auth, ColorScheme cs, AppLocalizations l10n) {
    return Form(
      key: _formKey1,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller:   _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText:  l10n.emailLabel,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.emailRequired;
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return l10n.invalidEmail;
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _submitEmail,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: auth.isLoading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.sendOtpButton),
        ),
      ]),
    );
  }

  Widget _buildStep2(AuthProvider auth, ColorScheme cs, AppLocalizations l10n) {
    return Form(
      key: _formKey2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller:   _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign:    TextAlign.center,
          maxLength:    6,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
          decoration: const InputDecoration(counterText: '', prefixIcon: Icon(Icons.pin_outlined)),
          validator: (v) => (v == null || v.trim().length != 6) ? 'الرمز يجب أن يكون 6 أرقام' : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: auth.isLoading ? null : _submitEmail,
          child: Text(l10n.resendLink, style: TextStyle(color: cs.primary)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _submitOtp,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(l10n.nextButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() { _step = 1; _error = null; }),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(l10n.changeEmailButton),
        ),
      ]),
    );
  }

  Widget _buildStep3(AuthProvider auth, ColorScheme cs, AppLocalizations l10n) {
    return Form(
      key: _formKey3,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller:  _passCtrl,
          obscureText: _obscurePass,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText:  l10n.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          validator: (v) => (v == null || v.length < 8) ? l10n.passwordTooShort : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller:  _confirmPassCtrl,
          obscureText: _obscureConfirm,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText:  'تأكيد كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (v) => v != _passCtrl.text ? l10n.passwordsNoMatch : null,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _submitReset,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: auth.isLoading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.changePasswordButton),
        ),
      ]),
    );
  }
}

// ── مؤشر الخطوات ──────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int   currentStep;
  final Color primaryColor;
  const _StepIndicator({required this.currentStep, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final inactive = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: List.generate(3, (i) {
        final step     = i + 1;
        final isActive = step <= currentStep;
        final isDone   = step < currentStep;
        return Expanded(
          child: Row(children: [
            Expanded(child: Container(
              height: 4,
              decoration: BoxDecoration(
                color:        isActive ? primaryColor : inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            if (i < 2) const SizedBox(width: 4),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color:        isActive ? primaryColor : inactive,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text('$step',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.white70,
                      )),
              ),
            ),
            if (i < 2) const SizedBox(width: 4),
          ]),
        );
      }),
    );
  }
}
