import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _convs   = [];
  bool          _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.get(ApiConfig.messages);
    if (mounted) setState(() {
      _loading = false;
      if (r['success'] == true) _convs = r['data']?['conversations'] as List? ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل الخاصة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _convs.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('لا توجد رسائل بعد', style: TextStyle(color: Colors.grey)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _convs.length,
                    separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
                    itemBuilder: (_, i) {
                      final c = _convs[i] as Map<String, dynamic>;
                      final unread = (c['unread'] as int? ?? 0) > 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text((c['full_name'] as String? ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        title: Text(c['full_name'] ?? '', style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
                        subtitle: Text(c['last_msg'] ?? '', overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12)),
                        trailing: unread
                            ? Badge(label: Text('${c['unread']}'), child: const SizedBox.shrink())
                            : null,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => _ChatScreen(userId: c['user_id'] as int, name: c['full_name'] as String? ?? ''),
                        )).then((_) => _load()),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ChatScreen extends StatefulWidget {
  final int userId; final String name;
  const _ChatScreen({required this.userId, required this.name});
  @override State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  List<dynamic> _msgs = [];
  final _msgCtrl      = TextEditingController();
  final _scroll       = ScrollController();
  bool _sending       = false;

  @override
  void initState() { super.initState(); _load(); }
  @override void dispose() { _msgCtrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    final r = await ApiService.get(ApiConfig.messages, params: {'with': '${widget.userId}'});
    if (mounted) setState(() { if (r['success'] == true) _msgs = r['data']?['messages'] as List? ?? []; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    await ApiService.post(ApiConfig.messages, {'to_id': widget.userId, 'message': txt});
    if (mounted) setState(() => _sending = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?['user_id'] as int?;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final m   = _msgs[i] as Map<String, dynamic>;
              final senderId = m['sender_id'] as int?;
              final isMine = currentUserId != null && senderId == currentUserId;
              return Align(
                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .7),
                  decoration: BoxDecoration(
                    color: isMine ? const Color(0xFF2563EB) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 4)],
                  ),
                  child: Text(m['content'] ?? '', style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 14, height: 1.4)),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF1F5F9), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)), maxLines: null, textDirection: TextDirection.rtl)),
            const SizedBox(width: 8),
            CircleAvatar(backgroundColor: const Color(0xFF2563EB), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send)),
          ]),
        ),
      ]),
    );
  }
}
