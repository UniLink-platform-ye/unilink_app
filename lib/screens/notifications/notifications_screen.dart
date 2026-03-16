import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs  = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.get(ApiConfig.notifications);
    if (mounted) {
      setState(() {
        _loading = false;
        if (r['success'] == true) {
          _notifs = r['data']?['notifications'] as List? ?? [];
          // علّم الإشعارات كمقروءة بعد جلبها بنجاح
          ApiService.post(ApiConfig.notifications, {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 12), Text('لا توجد إشعارات', style: TextStyle(color: Colors.grey)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
                    itemBuilder: (_, i) {
                      final n = _notifs[i] as Map<String, dynamic>;
                      final typeEmoji = {'new_post':'📝','new_message':'💬','post_like':'❤️','post_comment':'💬','group_invite':'👥','report_update':'📋','announcement':'📢','account_warning':'⚠️'}[n['type']] ?? '🔔';
                      final created  = DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
                      final content  = n['content'] ?? n['title'] ?? n['message'] ?? '';
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFFEFF6FF), child: Text(typeEmoji, style: const TextStyle(fontSize: 22))),
                        title: Text(content, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(timeago.format(created, locale: 'ar'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
