import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _all = [], _mine = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); _load(); }
  @override void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r1 = await ApiService.get(ApiConfig.groups);
    final r2 = await ApiService.get(ApiConfig.groups, params: {'filter': 'mine'});
    if (mounted) setState(() {
      _loading = false;
      if (r1['success'] == true) _all  = r1['data']?['groups'] as List? ?? [];
      if (r2['success'] == true) _mine = r2['data']?['groups'] as List? ?? [];
    });
  }

  Future<void> _join(int gid) async {
    await ApiService.post(ApiConfig.groups, {'action': 'join', 'group_id': gid});
    _load();
  }
  Future<void> _leave(int gid) async {
    await ApiService.post(ApiConfig.groups, {'action': 'leave', 'group_id': gid});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات الأكاديمية'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'الكل'), Tab(text: 'مجموعاتي')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _GroupList(groups: _all,  onJoin: _join, onLeave: _leave, onRefresh: _load),
              _GroupList(groups: _mine, onJoin: _join, onLeave: _leave, onRefresh: _load),
            ]),
    );
  }
}

class _GroupList extends StatelessWidget {
  final List<dynamic> groups;
  final Function(int) onJoin, onLeave;
  final Future<void> Function() onRefresh;
  const _GroupList({required this.groups, required this.onJoin, required this.onLeave, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const Center(child: Text('لا توجد مجموعات', style: TextStyle(color: Colors.grey)));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: groups.length,
        itemBuilder: (_, i) {
          final g = groups[i] as Map<String, dynamic>;
          final isMember = (g['is_member'] as int? ?? 0) > 0;
          final typeIcons = {'course':'📚','department':'🏛️','activity':'⚽','administrative':'📋'};
          final icon = typeIcons[g['type'] ?? g['group_type']] ?? '👥';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFEFF6FF), child: Text(icon, style: const TextStyle(fontSize: 22))),
              title: Text(g['group_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text('${g['member_count'] ?? 0} عضو • ${g['creator_name'] ?? ''}', style: const TextStyle(fontSize: 12)),
              trailing: isMember
                  ? OutlinedButton(onPressed: () => onLeave((g['group_id'] as int)), child: const Text('مغادرة', style: TextStyle(fontSize: 12)))
                  : ElevatedButton(onPressed: () => onJoin((g['group_id'] as int)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)), child: const Text('انضمام', style: TextStyle(fontSize: 12))),
            ),
          );
        },
      ),
    );
  }
}
