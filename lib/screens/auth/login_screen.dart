import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _obscure   = true;
  String? _error;
  bool _showUnverifiedResend = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

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
      setState(() {
        _error = err;
        _showUnverifiedResend = err.contains('غير مفعّل') || err.contains('تفعيله');
      });
    }
  }

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
    final auth     = context.watch<AuthProvider>();
    final tp       = context.watch<ThemeProvider>();
    final branding = tp.branding;
    final cs       = Theme.of(context).colorScheme;
    final l10n     = AppLocalizations.of(context);
    // خلفية تراعي الوضع الداكن
    final bgColor  = cs.surface;
    final textColor = cs.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // ── الشعار ──────────────────────────────────────
                    Center(
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _buildLogoWidget(branding.logoUrl),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── اسم المنصة ─────────────────────────────────
                    Text(
                      branding.platformName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: branding.fontFamily,
                        fontSize:   20,
                        fontWeight: FontWeight.w900,
                        color:      cs.primary,
                      ),
                    ),

                    if (branding.platformTagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        branding.platformTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: branding.fontFamily,
                          color:      textColor.withOpacity(0.6),
                          fontSize:   14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // ── خطأ ───────────────────────────────────────
                    if (_error != null) ...[
                      _ErrorCard(message: _error!),
                      if (_showUnverifiedResend) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: auth.isLoading ? null : _resendVerification,
                          icon: const Icon(Icons.email_outlined, size: 20),
                          label: const Text('إعادة إرسال رمز التفعيل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(color: cs.primary),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // ── البريد ────────────────────────────────────
                    TextFormField(
                      controller:   _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText:  l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? l10n.emailRequired : null,
                    ),
                    const SizedBox(height: 14),

                    // ── كلمة المرور ────────────────────────────────
                    TextFormField(
                      controller:  _password,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText:  l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6 ? l10n.passwordTooShort : null,
                    ),
                    const SizedBox(height: 24),

                    // ── زر الدخول ─────────────────────────────────
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: auth.isLoading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.loginButton),
                    ),
                    const SizedBox(height: 4),

                    // ── نسيت كلمة المرور؟ ─────────────────────────
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text(
                          l10n.forgotPassword,
                          style: TextStyle(color: cs.primary, fontSize: 13),
                        ),
                      ),
                    ),

                    // ── رابط التسجيل ──────────────────────────────
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text(
                        l10n.noAccount,
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── زر إعدادات السيرفر ───────────────────────────────
            Positioned(
              top: 8, left: 8,
              child: IconButton(
                icon: Icon(Icons.settings, color: textColor.withOpacity(0.4)),
                tooltip: l10n.serverSettings,
                onPressed: () => showServerConfigDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoWidget(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        placeholder: (_, __) => Image.asset('assets/images/logo.png', fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        cs.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: cs.error.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: cs.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: cs.error, fontSize: 13))),
      ]),
    );
  }
}
