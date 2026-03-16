import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final u = await ApiService.getUser();
    if (mounted) setState(() => _user = u);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_user == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_user!['full_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Center(child: CircleAvatar(
                  radius: 50, backgroundColor: Colors.white24,
                  child: Text((_user!['full_name'] as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                )),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج', onPressed: () async {
                await auth.logout();
                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                  child: Text({'admin':'مدير النظام','supervisor':'مشرف','professor':'أستاذ','student':'طالب'}[_user!['role']] ?? '', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                // Info Cards
                _InfoCard(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: _user!['email'] ?? ''),
                if (_user!['academic_id'] != null && _user!['academic_id'].toString().isNotEmpty)
                  _InfoCard(icon: Icons.badge_outlined, label: 'الرقم الأكاديمي', value: _user!['academic_id']),
                if (_user!['department'] != null && _user!['department'].toString().isNotEmpty)
                  _InfoCard(icon: Icons.school_outlined, label: 'القسم', value: _user!['department']),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(48)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoCard({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(leading: Icon(icon, color: const Color(0xFF2563EB)), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
    );
  }
}
