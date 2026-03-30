import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/theme_provider.dart';
import '../services/branding_service.dart';

void showServerConfigDialog(BuildContext context) {
  final ctrl = TextEditingController(text: ApiConfig.serverIp);

  showDialog(
    context: context,
    builder: (ctx) {
      bool   isTesting  = false;
      bool   isSaving   = false;
      String? testResult;
      bool   isSuccess  = false;

      return StatefulBuilder(
        builder: (context, setState) {

          // ── فحص الاتصال ──────────────────────────────────────
          Future<void> testConnection() async {
            final ip = ctrl.text.trim();
            if (ip.isEmpty) return;

            setState(() { isTesting = true; testResult = null; });

            try {
              final url = Uri.parse(
                'http://$ip/Trusted-Social-Network-Platform/api/v1/feed.php',
              );
              await http.get(url).timeout(const Duration(seconds: 5));
              setState(() {
                isTesting  = false;
                isSuccess  = true;
                testResult = '✓ السيرفر يعمل بنجاح!';
              });
            } catch (_) {
              setState(() {
                isTesting  = false;
                isSuccess  = false;
                testResult = 'فشل الاتصال — تأكد من العنوان أو الشبكة';
              });
            }
          }

          // ── حفظ IP + جلب Branding ────────────────────────────
          Future<void> saveAndFetch() async {
            final ip = ctrl.text.trim();
            if (ip.isEmpty) return;

            setState(() { isSaving = true; });

            // 1) حفظ الـ IP الجديد
            await ApiConfig.setHost(ip);

            // 2) مسح الـ cache القديم وجلب branding جديد من السيرفر
            BrandingService.resetSessionCache();
            await BrandingService.clearDiskCache();

            // 3) جلب branding وتطبيقه
            if (ctx.mounted) {
              final tp = ctx.read<ThemeProvider>();
              await tp.refreshBranding();
            }

            setState(() { isSaving = false; });

            if (ctx.mounted) Navigator.pop(ctx);
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.wifi_rounded, size: 20),
                SizedBox(width: 8),
                Text('إعدادات السيرفر'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:      MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أدخل عنوان IP السيرفر\n(مثال: 192.168.1.20 أو 10.0.2.2 للمحاكي)',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 12),

                  // ── حقل الـ IP ────────────────────────────────
                  TextField(
                    controller:   ctrl,
                    decoration: const InputDecoration(
                      labelText:  'IP السيرفر',
                      hintText:   '192.168.x.x',
                      prefixIcon: Icon(Icons.router_outlined),
                    ),
                    textDirection: TextDirection.ltr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  // ── زر الفحص ─────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: (isTesting || isSaving) ? null : testConnection,
                    icon: isTesting
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sensors, size: 18),
                    label: Text(isTesting ? 'جاري الفحص...' : 'فحص الاتصال'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isSuccess ? Colors.green : const Color(0xFF2563EB),
                      side: BorderSide(
                          color: isSuccess ? Colors.green : const Color(0xFF2563EB)),
                    ),
                  ),

                  // ── نتيجة الفحص ──────────────────────────────
                  if (testResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:        isSuccess
                            ? Colors.green.withOpacity(0.08)
                            : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSuccess
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        testResult!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.bold,
                          color:      isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],

                  // ── تلميح عند النجاح ─────────────────────────
                  if (isSuccess) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '💡 عند الحفظ سيتم جلب إعدادات الهوية من السيرفر وتطبيقها تلقائياً.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: isSaving ? null : saveAndFetch,
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(isSaving ? 'جاري الحفظ...' : 'حفظ وتطبيق'),
              ),
            ],
          );
        },
      );
    },
  );
}
