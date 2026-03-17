import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';

class SmartSearchScreen extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'ابحث عن مستخدم، مجموعة، منشور، مقرر...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('اكتب عبارة للبحث الشامل داخل المنصة'));
    }
    return _buildResults();
  }

  Widget _buildResults() {
    final q = query.trim();
    if (q.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.get(ApiConfig.search, params: {'q': q}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final res = snapshot.data;
        if (res == null || res['success'] != true) {
          return const Center(child: Text('حدث خطأ أثناء البحث'));
        }
        final users = res['data']?['users'] as List? ?? [];
        final groups = res['data']?['groups'] as List? ?? [];
        final posts = res['data']?['posts'] as List? ?? [];
        final courses = res['data']?['courses'] as List? ?? [];

        return ListView(
          children: [
            if (users.isNotEmpty) ...[
              const _SectionHeader(title: 'مستخدمون'),
              ...users.map((u) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(u['full_name'] ?? ''),
                    subtitle: Text(u['department'] ?? ''),
                  )),
              const Divider(),
            ],
            if (groups.isNotEmpty) ...[
              const _SectionHeader(title: 'مجموعات'),
              ...groups.map((g) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.groups)),
                    title: Text(g['group_name'] ?? ''),
                    subtitle: Text(g['description'] ?? ''),
                  )),
              const Divider(),
            ],
            if (posts.isNotEmpty) ...[
              const _SectionHeader(title: 'منشورات'),
              ...posts.map((p) => ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text((p['content'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(p['full_name'] ?? ''),
                  )),
              const Divider(),
            ],
            if (courses.isNotEmpty) ...[
              const _SectionHeader(title: 'مقررات'),
              ...courses.map((c) => ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text('${c['code'] ?? ''} — ${c['name'] ?? ''}'),
                    subtitle: Text(c['department'] ?? ''),
                  )),
              const Divider(),
            ],
            if (users.isEmpty && groups.isEmpty && posts.isEmpty && courses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('لا توجد نتائج مطابقة')),
              ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }
}

