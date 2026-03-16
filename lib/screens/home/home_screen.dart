import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'feed_screen.dart';
import 'groups_screen.dart';
import 'messages_screen.dart';
import '../notifications/notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadNotif  = 0;
  int _unreadMsg    = 0;

  final _screens = const [
    FeedScreen(),
    GroupsScreen(),
    MessagesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final results = await Future.wait([
        ApiService.get(ApiConfig.notifications),
        ApiService.get(ApiConfig.messages),
      ]);
      if (!mounted) return;
      final rNotif = results[0];
      final rMsg   = results[1];
      setState(() {
        if (rNotif['success'] == true) _unreadNotif = (rNotif['data']?['unread_count'] as int?) ?? 0;
        if (rMsg['success'] == true) {
          final convs = rMsg['data']?['conversations'] as List? ?? [];
          _unreadMsg = convs.fold<int>(0, (sum, c) => sum + ((c['unread'] as int?) ?? 0));
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() { _currentIndex = i; if (i == 3) _unreadNotif = 0; });
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'مجموعات'),
          NavigationDestination(
            icon: Badge(isLabelVisible: _unreadMsg > 0, label: Text('$_unreadMsg'), child: const Icon(Icons.message_outlined)),
            selectedIcon: const Icon(Icons.message),
            label: 'رسائل',
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: _unreadNotif > 0, label: Text('$_unreadNotif'), child: const Icon(Icons.notifications_outlined)),
            selectedIcon: const Icon(Icons.notifications),
            label: 'إشعارات',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'ملفي'),
        ],
      ),
    );
  }
}
