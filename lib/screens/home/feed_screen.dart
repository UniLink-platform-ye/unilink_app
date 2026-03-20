import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'messages_screen.dart';
import '../support/support_tickets_screen.dart';
import 'comments_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _posts  = [];
  bool          _loading = true;
  bool          _isLoadingMore = false; // منع التحميل المزدوج
  int           _page    = 1;
  bool          _hasMore = true;
  final _postCtrl = TextEditingController();

  @override
  void initState() { super.initState(); timeago.setLocaleMessages('ar', timeago.ArMessages()); _load(); }

  Future<void> _load({bool refresh = false}) async {
    if (_isLoadingMore && !refresh) return; // منع التحميل المتكرر
    if (refresh) { setState(() { _page = 1; _hasMore = true; _posts = []; _isLoadingMore = false; }); }
    setState(() { _loading = true; _isLoadingMore = true; });
    final r = await ApiService.get(ApiConfig.feed, params: {'page': '$_page'});
    if (mounted) {
      setState(() {
        _loading = false;
        _isLoadingMore = false;
        if (r['success'] == true) {
          final list = r['data']?['posts'] as List? ?? [];
          _posts   = refresh ? list : [..._posts, ...list];
          _hasMore = r['data']?['has_more'] == true;
          if (_hasMore) _page++;
        }
      });
    }
  }

  Future<void> _createPost() async {
    final txt = _postCtrl.text.trim();
    if (txt.isEmpty) return;
    final r = await ApiService.post(ApiConfig.posts, {'content': txt, 'post_type': 'post'});
    if (r['success'] == true && mounted) {
      _postCtrl.clear();
      _load(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniLink — الخلاصة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(refresh: true)),
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'الدعم الفني',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: CustomScrollView(
          slivers: [
            // Create Post Card
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF2563EB), radius: 20, child: Icon(Icons.person, color: Colors.white, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _postCtrl,
                          decoration: InputDecoration(
                            hintText: 'شارك شيئاً مع زملائك...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
                        onPressed: _createPost,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Posts
            if (_loading && _posts.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_posts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('لا توجد منشورات بعد', style: TextStyle(color: Colors.grey)),
                ])),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i == _posts.length) {
                      if (_hasMore) {
                        if (!_isLoadingMore) _load();
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      return const SizedBox.shrink();
                    }
                    final p = _posts[i] as Map<String, dynamic>;
                    return _PostCard(post: p, onRefresh: () => _load(refresh: true));
                  },
                  childCount: _posts.length + 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;
  const _PostCard({required this.post, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now();
    final timeStr = timeago.format(created, locale: 'ar');
    final type    = post['type'] ?? post['post_type'] ?? 'post';
    final typeIcons = {'post':'📝','announcement':'📢','question':'❓','lecture':'📚'};

    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?['user_id'] as int?;
    final postUserId = post['user_id'] as int?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2563EB),
                child: Text((post['full_name'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ])),
              if (currentUserId != null && postUserId != null && currentUserId != postUserId) ...[
                IconButton(
                  icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                  tooltip: 'إبلاغ عن منشور',
                  onPressed: () async {
                    final reason = await _showReportDialog(context);
                    if (reason == null) return;
                    await ApiService.post(ApiConfig.reports, {
                      'post_id': post['post_id'],
                      'reason': reason,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
                  tooltip: 'مراسلة',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(userId: postUserId, name: post['full_name'] as String? ?? ''),
                  )),
                ),
              ] else if (currentUserId == postUserId)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') _deletePost(context);
                    if (v == 'edit') _editPost(context);
                  },
                )
              else
                Text(typeIcons[type] ?? '📝', style: const TextStyle(fontSize: 18)),
            ]),
            // Group tag
            if (post['group_name'] != null) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                child: Text('👥 ${post['group_name']}', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(post['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(post: post)));
                  },
                  icon: const Icon(Icons.comment_outlined, size: 20),
                  label: Text('التعليقات (${post['comments_count'] ?? 0})', style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Future<void> _deletePost(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنشور؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (sure != true) return;
    
    final r = await ApiService.delete(ApiConfig.posts, params: {'id': post['post_id'].toString()});
    if (context.mounted) {
      if (r['success'] == true) {
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'حدث خطأ')));
      }
    }
  }

  Future<void> _editPost(BuildContext context) async {
    final ctrl = TextEditingController(text: post['content'] ?? '');
    final newContent = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل المنشور'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'محتوى المنشور...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('حفظ')),
        ],
      )
    );

    if (newContent == null || newContent.trim().isEmpty || newContent == post['content']) return;

    final r = await ApiService.post(ApiConfig.posts, {'action': 'edit', '_method': 'PUT', 'post_id': post['post_id'], 'content': newContent.trim()});
    if (context.mounted) {
      if (r['success'] == true) {
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'حدث خطأ في التعديل')));
      }
    }
  }
}
