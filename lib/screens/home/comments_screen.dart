import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class CommentsScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  bool _loading = true;
  List<dynamic> _comments = [];
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    final r = await ApiService.get(ApiConfig.comments, params: {'post_id': widget.post['post_id'].toString()});
    if (mounted) {
      setState(() {
        _loading = false;
        if (r['success'] == true) {
          _comments = r['data']?['comments'] ?? [];
        }
      });
    }
  }

  Future<void> _addComment() async {
    final txt = _commentCtrl.text.trim();
    if (txt.isEmpty) return;

    final r = await ApiService.post(ApiConfig.comments, {
      'post_id': widget.post['post_id'],
      'content': txt,
    });

    if (r['success'] == true && mounted) {
      _commentCtrl.clear();
      _loadComments();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['error']?.toString() ?? 'فشل إضافة التعليق')));
    }
  }

  Future<void> _deleteComment(int cid) async {
    final r = await ApiService.delete(ApiConfig.comments, params: {'id': cid.toString()});
    if (r['success'] == true && mounted) {
      _loadComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?['user_id'] as int?;
    final role = auth.user?['role'] as String?;
    final isAdmin = role == 'admin' || role == 'supervisor';
    final postOwnerId = widget.post['user_id'] as int?;

    return Scaffold(
      appBar: AppBar(title: const Text('التعليقات')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('لا توجد تعليقات، كن أول من يعلق!'))
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, i) {
                          final c = _comments[i];
                          final cid = c['comment_id'] as int;
                          final cOwnerId = c['user_id'] as int;
                          final canDelete = currentUserId == cOwnerId || currentUserId == postOwnerId || isAdmin;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text((c['full_name'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(c['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(c['content'] ?? '', style: const TextStyle(fontSize: 14)),
                            trailing: canDelete
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _deleteComment(cid),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقاً...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
