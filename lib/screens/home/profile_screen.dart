import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../file_center/file_center_screen.dart';
import '../calendar/calendar_screen.dart';
import '../support/support_tickets_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final u = await ApiService.getUser();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tp         = context.watch<ThemeProvider>();
    final lp         = context.watch<LocaleProvider>();
    final cs         = Theme.of(context).colorScheme;
    final l10n       = AppLocalizations.of(context)!;

    if (_user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    final roleLabels = {
      'admin':      'Admin',
      'supervisor': 'Supervisor',
      'professor':  l10n.professorRole,
      'student':    l10n.studentRole,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar موسّع ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned:         true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _user!['full_name'] ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius:          50,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (_user!['full_name'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: l10n.logout,
                onPressed: _logout,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                // ── Role Badge ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color:        cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabels[_user!['role']] ?? _user!['role'] ?? '',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 20),

                // ── معلومات المستخدم ───────────────────────────
                _InfoCard(icon: Icons.email_outlined, label: l10n.emailLabel, value: _user!['email'] ?? ''),
                if ((_user!['academic_id']?.toString() ?? '').isNotEmpty)
                  _InfoCard(icon: Icons.badge_outlined, label: l10n.academicIdLabel, value: _user!['academic_id'].toString()),
                if ((_user!['department']?.toString() ?? '').isNotEmpty)
                  _InfoCard(icon: Icons.school_outlined, label: l10n.departmentLabel, value: _user!['department'].toString()),

                const SizedBox(height: 24),

                // ── وضع الثيم ─────────────────────────────────
                Card(
                  child: ListTile(
                    leading: Icon(
                      tp.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: cs.primary,
                    ),
                    title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(tp.isDark ? l10n.darkMode : l10n.lightMode, style: const TextStyle(fontSize: 12)),
                    trailing: Switch(
                      value:     tp.isDark,
                      onChanged: (_) => tp.toggle(),
                      activeColor: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── تغيير اللغة ───────────────────────────────
                Card(
                  child: ListTile(
                    leading: Icon(Icons.language, color: cs.primary),
                    title: Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(lp.isArabic ? l10n.arabic : l10n.english, style: const TextStyle(fontSize: 12)),
                    trailing: Switch(
                      value:      lp.isArabic,
                      onChanged: (_) => lp.toggle(),
                      activeColor: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── مركز الملفات ──────────────────────────────
                Card(
                  child: ListTile(
                    leading: Icon(Icons.folder_open, color: cs.primary),
                    title: Text(l10n.files, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(l10n.filesSubtitle, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FileCenterScreen())),
                  ),
                ),
                const SizedBox(height: 8),

                // ── التقويم ───────────────────────────────────
                Card(
                  child: ListTile(
                    leading: Icon(Icons.calendar_today_outlined, color: cs.primary),
                    title: Text(l10n.calendar, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(l10n.calendarSubtitle, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                  ),
                ),
                const SizedBox(height: 8),

                // ── الدعم الفني ───────────────────────────────
                Card(
                  child: ListTile(
                    leading: Icon(Icons.support_agent_outlined, color: cs.primary),
                    title: Text(l10n.support, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(l10n.supportSubtitle, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen())),
                  ),
                ),
                const SizedBox(height: 16),

                // ── تسجيل الخروج ──────────────────────────────
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon:  const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    minimumSize:     const Size.fromHeight(48),
                  ),
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
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:  Icon(icon, color: cs.primary),
        title:    Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55))),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}
