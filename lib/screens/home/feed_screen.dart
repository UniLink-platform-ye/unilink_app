import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/api_service.dart';
import '../../config/api_config.dart';

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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('UniLink — الخلاصة'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(refresh: true))],
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
                            filled: true, fillColor: const Color(0xFFF1F5F9),
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
                    return _PostCard(post: p);
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
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now();
    final timeStr = timeago.format(created, locale: 'ar');
    final type    = post['type'] ?? post['post_type'] ?? 'post';
    final typeIcons = {'post':'📝','announcement':'📢','question':'❓','lecture':'📚'};

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
          ],
        ),
      ),
    );
  }
}
