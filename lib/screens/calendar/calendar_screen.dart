import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
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
    final currentUserId = context.watch<AuthProvider>().user?['user_id'] as int?;
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

                      final isOwner = currentUserId != null && currentUserId == e['owner_user_id'];

                      return ListTile(
                        leading: Icon(icon, color: const Color(0xFF2563EB)),
                        title: Text(e['title'] ?? ''),
                        subtitle: Text(subtitleParts.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: isOwner
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => EventFormScreen(initial: e)));
                                      if (mounted) _load();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteEvent(e),
                                  ),
                                ],
                              )
                            : null,
                        onTap: () => _showEventDetailsDialog(e),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _deleteEvent(Map<String, dynamic> e) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الحدث؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (sure != true) return;
    
    final r = await ApiService.delete('${ApiConfig.calendar}?id=${e['event_id']}');
    if (mounted) {
      if (r['success'] == true) _load();
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'حدث خطأ')));
    }
  }

  void _showEventDetailsDialog(Map<String, dynamic> e) {
    final typeLabels = {
      'lecture': 'محاضرة',
      'exam': 'اختبار',
      'meeting': 'اجتماع',
      'task': 'مهمة',
      'other': 'أخرى',
    };
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e['title'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e['event_type'] != null)
              Text('النوع: ${typeLabels[e['event_type']] ?? e['event_type']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('من: ${e['start_at'] ?? ''}'),
            if (e['end_at'] != null) Text('إلى: ${e['end_at']}'),
            if ((e['location'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('الموقع: ${e['location']}'),
            ],
            if ((e['course_name'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('المقرر: ${e['course_name']}'),
            ],
            if ((e['group_name'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('المجموعة: ${e['group_name']}'),
            ],
            if ((e['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('الوصف:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(e['description'] ?? ''),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
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

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // صيغة متوافقة مع MySQL: yyyy-MM-dd HH:mm:ss
    controller.text = '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
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
      
      final isEdit = widget.initial != null;
      final url = isEdit ? '${ApiConfig.calendar}?id=${widget.initial!['event_id']}' : ApiConfig.calendar;
      final r = isEdit ? await ApiService.put(url, body) : await ApiService.post(url, body);
      
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
            readOnly: true,
            onTap: () => _pickDateTime(_startCtrl),
            decoration: const InputDecoration(
              labelText: 'بداية الحدث',
              hintText: 'اختر التاريخ والوقت',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _endCtrl,
            readOnly: true,
            onTap: () => _pickDateTime(_endCtrl),
            decoration: const InputDecoration(
              labelText: 'نهاية الحدث (اختياري)',
              hintText: 'اختر التاريخ والوقت',
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

