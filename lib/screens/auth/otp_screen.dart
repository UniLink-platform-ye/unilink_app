import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String emailMasked;
  const OtpScreen({super.key, required this.emailMasked});
  @override State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode>             _nodes = List.generate(6, (_) => FocusNode());
  int   _seconds = 300; // 5 دقائق
  int   _resendCooldown = 0; // عد تنازلي لإعادة الإرسال (ثانية)
  Timer? _timer;
  Timer? _resendTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldown > 0) { setState(() => _resendCooldown--); }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) { setState(() => _seconds--); }
      else { _timer?.cancel(); }
    });
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) { setState(() => _error = 'أدخل الرمز كاملاً (6 أرقام)'); return; }
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res  = await auth.verifyOtp(_otp);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else {
      setState(() => _error = res['error'] as String? ?? 'رمز غير صحيح');
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final res = await auth.resendOtp();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _resendCooldown = 60;
        for (final c in _ctrls) c.clear();
        _nodes[0].requestFocus();
      });
      _startTimer();
    } else {
      setState(() => _error = res['error'] as String? ?? 'فشل إعادة الإرسال');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('التحقق برمز OTP'), leading: const BackButton()),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 64, color: Color(0xFF2563EB)),
                      const SizedBox(height: 16),
                      Text('أرسلنا رمزاً إلى ${widget.emailMasked}', textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Text(_timeStr, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                          color: _seconds < 60 ? Colors.red : const Color(0xFF2563EB))),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) => SizedBox(
                          width: 46, height: 56,
                          child: TextFormField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true, fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty && i < 5) { FocusScope.of(context).requestFocus(_nodes[i + 1]); }
                              if (v.isEmpty && i > 0)     { FocusScope.of(context).requestFocus(_nodes[i - 1]); }
                              if (_otp.length == 6)       { _verify(); }
                            },
                          ),
                        )),
                      ),
                      const SizedBox(height: 16),

                      if (_error != null) Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                      ),

                      ElevatedButton(
                        onPressed: auth.isLoading || _seconds == 0 ? null : _verify,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        child: auth.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('تحقق من الرمز'),
                      ),

                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: (_resendCooldown > 0 || auth.isLoading) ? null : _resendOtp,
                        icon: Icon(Icons.refresh, size: 20, color: _resendCooldown > 0 ? Colors.grey : const Color(0xFF2563EB)),
                        label: Text(
                          _resendCooldown > 0 ? 'إعادة إرسال الرمز ($_resendCooldown ث)' : 'إعادة إرسال الرمز',
                          style: TextStyle(color: _resendCooldown > 0 ? Colors.grey : const Color(0xFF2563EB), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
