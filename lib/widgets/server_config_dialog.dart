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
            final ip = ctrl.text.trim();
            if (ip.isEmpty) return;

            setState(() {
              isTesting = true;
              testResult = null;
            });

            try {
              // نقوم بطلب بسيط، حتى لو كان الرد 401 فهذا يعني أن السيرفر يعمل
              final url = Uri.parse('http://$ip/Trusted-Social-Network-Platform/api/v1/feed.php');
              await http.get(url).timeout(const Duration(seconds: 5));
              
              setState(() {
                isTesting = false;
                // إذا تمكنا من الوصول وحصلنا على رد (أيا كان رمز الحالة، فهذا يعني أن الشبكة صحيحة للسيرفر)
                isSuccess = true;
                testResult = 'تم الاتصال بنجاح السيرفر يعمل!';
              });
            } catch (e) {
              setState(() {
                isTesting = false;
                isSuccess = false;
                testResult = 'فشل الاتصال: تأكد من العنوان أو اتصال الشبكة';
              });
            }
          }

          return AlertDialog(
            title: const Text('إعدادات السيرفر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'أدخل عنوان IP السيرفر (مثال: 192.168.1.20 أو 10.0.2.2 للمحاكي)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'IP السيرفر',
                    hintText: '192.168.1.x',
                    prefixIcon: Icon(Icons.wifi_rounded),
                  ),
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isTesting ? null : testConnection,
                  icon: isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sensors),
                  label: Text(isTesting ? 'جاري الفحص...' : 'فحص الاتصال'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSuccess ? Colors.green : const Color(0xFF2563EB),
                    side: BorderSide(color: isSuccess ? Colors.green : const Color(0xFF2563EB)),
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
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final ip = ctrl.text.trim();
                  if (ip.isNotEmpty) {
                    await ApiConfig.setHost(ip);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
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
