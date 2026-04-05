import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.get(ApiConfig.support);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        _tickets = r['data']?['tickets'] as List? ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم الفني'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewTicketScreen()));
          if (mounted) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('تذكرة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('لا توجد تذاكر دعم حتى الآن'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _tickets.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final t = _tickets[i] as Map<String, dynamic>;
                      final status = t['status'] ?? 'open';
                      final chip = {
                        'open': const Chip(label: Text('مفتوحة'), backgroundColor: Color(0xFFEFF6FF)),
                        'pending': const Chip(label: Text('قيد المتابعة'), backgroundColor: Color(0xFFFFF7ED)),
                        'closed': const Chip(label: Text('مغلقة'), backgroundColor: Color(0xFFE5F6E9)),
                      }[status] ??
                          Chip(label: Text(status.toString()));
                      return ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: Text(t['subject'] ?? ''),
                        subtitle: Text('الأولوية: ${t['priority'] ?? 'normal'} • أنشئت في ${t['created_at'] ?? ''}', maxLines: 2),
                        trailing: chip,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticketId: t['ticket_id'] as int)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _priority = 'normal';
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = _subjectCtrl.text.trim();
    final m = _messageCtrl.text.trim();
    if (s.isEmpty || m.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final r = await ApiService.post(ApiConfig.support, {
        'action': 'create',
        'subject': s,
        'message': m,
        'priority': _priority,
      });
      if (!mounted) return;
      if (r['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء التذكرة')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'فشل إنشاء التذكرة')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تذكرة دعم جديدة')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(labelText: 'الموضوع', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _priority,
            items: const [
              DropdownMenuItem(value: 'low', child: Text('منخفضة')),
              DropdownMenuItem(value: 'normal', child: Text('متوسطة')),
              DropdownMenuItem(value: 'high', child: Text('مرتفعة')),
            ],
            onChanged: (v) => setState(() => _priority = v ?? 'normal'),
            decoration: const InputDecoration(labelText: 'الأولوية', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageCtrl,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'وصف المشكلة', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_sending ? 'جاري الإرسال...' : 'إرسال'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}

class TicketDetailsScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  bool _loading = true;
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.get(ApiConfig.support, params: {'id': '${widget.ticketId}'});
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        _ticket = r['data']?['ticket'] as Map<String, dynamic>?;
        _messages = r['data']?['messages'] as List? ?? [];
      }
    });
  }

  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService.post(ApiConfig.support, {
        'action': 'reply',
        'ticket_id': widget.ticketId,
        'message': txt,
      });
      _msgCtrl.clear();
      _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ticket;
    return Scaffold(
      appBar: AppBar(title: Text(t == null ? 'التذكرة' : t['subject'] ?? 'التذكرة')),
      body: _loading || t == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  title: Text(t['subject'] ?? ''),
                  subtitle: Text('الحالة: ${t['status'] ?? ''} • الأولوية: ${t['priority'] ?? ''}'),
                ),
                const Divider(height: 0),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i] as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['sender_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(m['message'] ?? '', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(m['created_at'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'أضف ردًا...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: IconButton(
                          icon: _sending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sending ? null : _send,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

