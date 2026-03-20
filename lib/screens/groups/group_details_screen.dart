import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../calendar/calendar_screen.dart';
import '../file_center/file_upload_screen.dart';
import '../home/comments_screen.dart';

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
    // نستنتج رابط group_details.php من أي endpoint موجود (مثلاً groups)
    final base = ApiConfig.groups.replaceFirst('groups.php', 'group_details.php');
    final r = await ApiService.get(base, params: {'group_id': '$groupId'});
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
    
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?['user_id'] as int?;
    final role = auth.user?['role'] as String?;
    final isOwnerOrAdmin = (currentUserId != null && currentUserId == g['created_by']) || role == 'admin' || role == 'supervisor';

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
          future: ApiService.get(ApiConfig.groups.replaceFirst('groups.php', 'group_details.php'), params: {'group_id': '$groupId'}),
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
              children: [
                if (isOwnerOrAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('إضافة عضو'),
                      onPressed: () async {
                        final u = await showSearch(context: context, delegate: _UserSearchDelegate());
                        if (u != null && mounted) {
                          final r = await ApiService.post(ApiConfig.groupsManage, {
                            'action': 'add_member',
                            'group_id': groupId,
                            'user_id': u['user_id'],
                          });
                          if (r['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة العضو بنجاح')));
                            _loadDetails();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'فشل إضافة العضو')));
                          }
                        }
                      },
                    ),
                  ),
                ...members.map((m) {
                  final uid = m['user_id'] as int?;
                  final isOwner = m['member_role'] == 'owner';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(m['full_name'] ?? ''),
                    subtitle: Text(m['user_role'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m['member_role'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        if (isOwnerOrAdmin && !isOwner && uid != null)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeMember(uid),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _removeMember(int uid) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الإزالة'),
        content: const Text('هل أنت متأكد من رغبتك في إزالة هذا العضو من المجموعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('إزالة', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (sure != true) return;
    
    final r = await ApiService.post(ApiConfig.groupsManage, {
      'action': 'remove_member',
      'group_id': groupId,
      'user_id': uid,
    });
    
    if (mounted) {
      if (r['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإزالة بنجاح')));
        _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'حدث خطأ أثناء الإزالة')));
      }
    }
  }

  Widget _buildPostsTab() {
    if (_loadingPosts) return const Center(child: CircularProgressIndicator());
    if (_posts.isEmpty) {
      return const Center(child: Text('لا توجد منشورات في هذه المجموعة بعد'));
    }
    
    final currentUserId = context.watch<AuthProvider>().user?['user_id'] as int?;
    
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (_, i) {
          final p = _posts[i] as Map<String, dynamic>;
          final postUserId = p['user_id'] as int?;
          final isMine = currentUserId != null && currentUserId == postUserId;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(p['content'] ?? ''),
                  subtitle: Text(p['full_name'] ?? ''),
                  trailing: isMine
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                            const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (v) {
                            if (v == 'delete') _deletePost(p);
                            if (v == 'edit') _editPost(p);
                          },
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'report', child: Text('الإبلاغ عن المنشور')),
                          ],
                          onSelected: (v) async {
                            if (v == 'report') {
                              final reason = await _showReportDialog(context);
                              if (reason != null && mounted) {
                                await ApiService.post(ApiConfig.reports, {'post_id': p['post_id'], 'reason': reason});
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')));
                              }
                            }
                          },
                        ),
                ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(post: p))),
                      icon: const Icon(Icons.comment_outlined, size: 20),
                      label: Text('التعليقات (${p['comments_count'] ?? 0})', style: const TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
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

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنشور؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (sure != true) return;
    
    final r = await ApiService.delete(ApiConfig.posts, params: {'id': post['post_id'].toString()});
    if (context.mounted) {
      if (r['success'] == true) _loadPosts();
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'حدث خطأ')));
    }
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final ctrl = TextEditingController(text: post['content'] ?? '');
    final newContent = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل المنشور'),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('حفظ')),
        ],
      )
    );

    if (newContent == null || newContent.trim().isEmpty || newContent == post['content']) return;

    final r = await ApiService.post(ApiConfig.posts, {'action': 'edit', '_method': 'PUT', 'post_id': post['post_id'], 'content': newContent.trim()});
    if (context.mounted) {
      if (r['success'] == true) _loadPosts();
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'حدث خطأ في التعديل')));
    }
  }

  Future<String?> _showReportDialog(BuildContext context) async {
    String? selected = 'inappropriate_content';
    final reasons = <String, String>{
      'spam': 'رسائل مزعجة / دعاية',
      'harassment': 'مضايقة أو إساءة',
      'inappropriate_content': 'محتوى غير مناسب',
      'misinformation': 'معلومات مضللة',
      'copyright_violation': 'انتهاك حقوق نشر',
      'other': 'أخرى',
    };
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إبلاغ عن منشور'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.entries
                .map((e) => RadioListTile<String>(
                      title: Text(e.value),
                      value: e.key,
                      groupValue: selected,
                      onChanged: (v) => setState(() => selected = v),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, selected), child: const Text('إرسال')),
        ],
      ),
    );
  }
}

class _UserSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  @override
  String get searchFieldLabel => 'ابحث عن زميل...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.trim().isEmpty) return const Center(child: Text('ابحث بالاسم أو القسم'));
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.get(ApiConfig.users, params: {'q': query}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final res = snapshot.data;
        if (res == null || res['success'] != true) return const Center(child: Text('حدث خطأ أثناء البحث'));
        final users = res['data']?['users'] as List? ?? [];
        if (users.isEmpty) return const Center(child: Text('لم يتم العثور على أحد'));
        
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final u = users[i] as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: Text((u['full_name'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(u['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(u['department'] ?? '', style: const TextStyle(fontSize: 12)),
              onTap: () => close(context, u),
            );
          },
        );
      },
    );
  }
}
