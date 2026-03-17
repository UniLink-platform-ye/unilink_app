import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.get(ApiConfig.calendar);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        _events = r['data']?['events'] as List? ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم الأكاديمي'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventFormScreen()));
          if (mounted) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('حدث جديد'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('لا توجد أحداث في التقويم بعد'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final e = _events[i] as Map<String, dynamic>;
                      final type = e['event_type'] ?? 'other';
                      final icon = {
                        'lecture': Icons.school_outlined,
                        'exam': Icons.fact_check_outlined,
                        'meeting': Icons.meeting_room_outlined,
                        'task': Icons.check_circle_outline,
                        'other': Icons.event_note_outlined,
                      }[type] ?? Icons.event_note_outlined;
                      final subtitleParts = <String>[];
                      if ((e['course_name'] ?? '').toString().isNotEmpty) {
                        subtitleParts.add('المقرر: ${e['course_name']}');
                      }
                      if ((e['group_name'] ?? '').toString().isNotEmpty) {
                        subtitleParts.add('المجموعة: ${e['group_name']}');
                      }
                      subtitleParts.add('من ${e['start_at']}');
                      if (e['end_at'] != null) subtitleParts.add('إلى ${e['end_at']}');

                      return ListTile(
                        leading: Icon(icon, color: const Color(0xFF2563EB)),
                        title: Text(e['title'] ?? ''),
                        subtitle: Text(subtitleParts.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
    );
  }
}

class EventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const EventFormScreen({super.key, this.initial});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  String _type = 'lecture';
  bool _allDay = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _titleCtrl.text = e['title'] ?? '';
      _descCtrl.text = e['description'] ?? '';
      _startCtrl.text = e['start_at'] ?? '';
      _endCtrl.text = e['end_at'] ?? '';
      _type = e['event_type'] ?? 'lecture';
      _allDay = (e['all_day'] as int? ?? 0) == 1;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _titleCtrl.text.trim().isEmpty || _startCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'start_at': _startCtrl.text.trim(),
        if (_endCtrl.text.trim().isNotEmpty) 'end_at': _endCtrl.text.trim(),
        'event_type': _type,
        'all_day': _allDay,
      };
      final r = await ApiService.post(ApiConfig.calendar, body);
      if (!mounted) return;
      if (r['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الحدث')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'فشل حفظ الحدث')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حدث جديد في التقويم')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'عنوان الحدث', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'lecture', child: Text('محاضرة')),
              DropdownMenuItem(value: 'exam', child: Text('اختبار')),
              DropdownMenuItem(value: 'meeting', child: Text('اجتماع')),
              DropdownMenuItem(value: 'task', child: Text('مهمة')),
              DropdownMenuItem(value: 'other', child: Text('أخرى')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'lecture'),
            decoration: const InputDecoration(labelText: 'نوع الحدث', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _startCtrl,
            decoration: const InputDecoration(
              labelText: 'بداية الحدث (YYYY-MM-DD HH:MM)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _endCtrl,
            decoration: const InputDecoration(
              labelText: 'نهاية الحدث (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _allDay,
            onChanged: (v) => setState(() => _allDay = v),
            title: const Text('حدث طوال اليوم'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}

