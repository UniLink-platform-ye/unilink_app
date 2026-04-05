import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

void showServerConfigDialog(BuildContext context) {
  final ctrl = TextEditingController(text: ApiConfig.serverIp);

  showDialog(
    context: context,
    builder: (ctx) {
      bool isTesting = false;
      String? testResult;
      bool isSuccess = false;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> testConnection() async {
            final candidate = ApiConfig.previewBaseUrl(ctrl.text.trim());
            if (candidate.isEmpty) {
              setState(() {
                isSuccess = false;
                testResult = 'أدخل عنوانًا صحيحًا أو رابط API كاملًا.';
              });
              return;
            }

            setState(() {
              isTesting = true;
              testResult = null;
            });

            try {
              final url = Uri.parse('$candidate/feed.php');
              await http.get(url).timeout(const Duration(seconds: 5));

              setState(() {
                isTesting = false;
                isSuccess = true;
                testResult = 'تم الوصول إلى الخادم بنجاح.';
              });
            } catch (_) {
              setState(() {
                isTesting = false;
                isSuccess = false;
                testResult = 'فشل الاتصال. تحقق من العنوان أو الشبكة.';
              });
            }
          }

          return AlertDialog(
            title: const Text('إعدادات الخادم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أدخل عنوان الخادم أو الرابط الأساسي للـ API. في الإنتاج استخدم HTTPS فقط.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'عنوان الخادم أو API Base URL',
                      hintText:
                          '10.0.2.2 أو https://api.example.com/Trusted-Social-Network-Platform/api/v1',
                      prefixIcon: Icon(Icons.wifi_rounded),
                    ),
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.url,
                    minLines: 1,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.text.trim().isNotEmpty)
                    Text(
                      ApiConfig.previewBaseUrl(ctrl.text.trim()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textDirection: TextDirection.ltr,
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isTesting ? null : testConnection,
                    icon: isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sensors),
                    label: Text(isTesting ? 'جاري الفحص...' : 'فحص الاتصال'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isSuccess ? Colors.green : const Color(0xFF2563EB),
                      side: BorderSide(
                        color:
                            isSuccess ? Colors.green : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      testResult!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSuccess ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiConfig.setHost(ctrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {
                    setState(() {
                      isSuccess = false;
                      testResult =
                          'تعذر حفظ العنوان. استخدم عنوانًا صحيحًا، ومع HTTPS في وضع الإنتاج.';
                    });
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      );
    },
  );
}
