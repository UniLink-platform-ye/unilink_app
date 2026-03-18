import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../calendar/calendar_screen.dart';
import '../file_center/file_upload_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _details;
  bool _loadingDetails = true;

  List<dynamic> _posts = [];
  bool _loadingPosts = true;

  List<dynamic> _files = [];
  bool _loadingFiles = true;

  List<dynamic> _events = [];
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int get groupId => widget.group['group_id'] as int;

  Future<void> _loadAll() async {
    await Future.wait([_loadDetails(), _loadPosts(), _loadFiles(), _loadEvents()]);
  }

  Future<void> _loadDetails() async {
    setState(() => _loadingDetails = true);
    final r = await ApiService.get(ApiConfig.host + '/group_details.php', params: {'group_id': '$groupId'});
    if (!mounted) return;
    setState(() {
      _loadingDetails = false;
      if (r['success'] == true) {
        _details = r['data']?['group'] as Map<String, dynamic>?;
      }
    });
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    final r = await ApiService.get(ApiConfig.feed, params: {'page': '1', 'group_id': '$groupId'});
    if (!mounted) return;
    setState(() {
      _loadingPosts = false;
      if (r['success'] == true) {
        _posts = r['data']?['posts'] as List? ?? [];
      }
    });
  }

  Future<void> _loadFiles() async {
    setState(() => _loadingFiles = true);
    final r = await ApiService.get(ApiConfig.files, params: {'group_id': '$groupId', 'limit': '50'});
    if (!mounted) return;
    setState(() {
      _loadingFiles = false;
      if (r['success'] == true) {
        _files = r['data']?['files'] as List? ?? [];
      }
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _loadingEvents = true);
    final r = await ApiService.get(ApiConfig.calendar, params: {'group_id': '$groupId'});
    if (!mounted) return;
    setState(() {
      _loadingEvents = false;
      if (r['success'] == true) {
        _events = r['data']?['events'] as List? ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = _details ?? widget.group;
    return Scaffold(
      appBar: AppBar(
        title: Text(g['group_name'] ?? 'المجموعة'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'حول'),
            Tab(text: 'المنشورات'),
            Tab(text: 'الملفات'),
            Tab(text: 'التقويم'),
          ],
        ),
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton(
              onPressed: () async {
                final txt = await _showCreatePostDialog(context);
                if (txt == null || txt.trim().isEmpty) return;
                await ApiService.post(ApiConfig.posts, {
                  'content': txt.trim(),
                  'post_type': 'post',
                  'group_id': groupId,
                });
                _loadPosts();
              },
              child: const Icon(Icons.edit),
            )
          : (_tabs.index == 2
              ? FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileUploadScreen(initialGroupId: groupId),
                      ),
                    );
                    _loadFiles();
                  },
                  child: const Icon(Icons.cloud_upload),
                )
              : null),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildAboutTab(g),
          _buildPostsTab(),
          _buildFilesTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> g) {
    if (_loadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(g['group_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(g['description'] ?? 'لا يوجد وصف', style: const TextStyle(fontSize: 13)),
        ),
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text('نوع المجموعة'),
          subtitle: Text(g['type'] ?? g['group_type'] ?? ''),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('الخصوصية'),
          subtitle: Text(g['privacy'] ?? ''),
        ),
        if ((g['course_name'] ?? '').toString().isNotEmpty)
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('المقرر المرتبط'),
            subtitle: Text('${g['course_code'] ?? ''} — ${g['course_name'] ?? ''}'),
          ),
        const SizedBox(height: 12),
        const Text('الأعضاء', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService.get(ApiConfig.host + '/group_details.php', params: {'group_id': '$groupId'}),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final res = snapshot.data;
            if (res == null || res['success'] != true) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('تعذر جلب قائمة الأعضاء'),
              );
            }
            final members = res['data']?['members'] as List? ?? [];
            if (members.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا يوجد أعضاء بعد'),
              );
            }
            return Column(
              children: members
                  .map(
                    (m) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(m['full_name'] ?? ''),
                      subtitle: Text(m['user_role'] ?? ''),
                      trailing: Text(
                        m['member_role'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if (_loadingPosts) return const Center(child: CircularProgressIndicator());
    if (_posts.isEmpty) {
      return const Center(child: Text('لا توجد منشورات في هذه المجموعة بعد'));
    }
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (_, i) {
          final p = _posts[i] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(p['content'] ?? ''),
              subtitle: Text(p['full_name'] ?? ''),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilesTab() {
    if (_loadingFiles) return const Center(child: CircularProgressIndicator());
    if (_files.isEmpty) {
      return const Center(child: Text('لا توجد ملفات مرتبطة بهذه المجموعة بعد'));
    }
    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _files.length,
        itemBuilder: (_, i) {
          final f = _files[i] as Map<String, dynamic>;
          final name = (f['title'] as String?)?.isNotEmpty == true ? f['title'] as String : (f['original_name'] as String? ?? 'ملف');
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(name),
              subtitle: Text('رفع بواسطة: ${f['uploader_name'] ?? ''}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_loadingEvents) return const Center(child: CircularProgressIndicator());
    if (_events.isEmpty) {
      return const Center(child: Text('لا توجد أحداث تقويم لهذه المجموعة بعد'));
    }
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        itemBuilder: (_, i) {
          final e = _events[i] as Map<String, dynamic>;
          return ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: Text(e['title'] ?? ''),
            subtitle: Text('من ${e['start_at']} ${e['end_at'] != null ? 'إلى ${e['end_at']}' : ''}'),
            onTap: () => _showEventDetailsDialog(e),
          );
        },
      ),
    );
  }

  Future<String?> _showCreatePostDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('منشور جديد في المجموعة'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اكتب ما تريد مشاركته مع أعضاء المجموعة...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('نشر')),
        ],
      ),
    );
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

