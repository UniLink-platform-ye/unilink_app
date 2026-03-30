import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: .7, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.loadSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp       = context.watch<ThemeProvider>();
    final branding = tp.branding;
    final primary  = branding.primaryColor;

    // لون خلفية الـ Splash = اللون الأساسي الداكن
    final splashBg = HSLColor.fromColor(primary)
        .withLightness(0.18)
        .toColor();

    return Scaffold(
      backgroundColor: splashBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── الشعار ──────────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildLogoWidget(branding.logoUrl),
                  ),
                ),

                const SizedBox(height: 20),

                // ── اسم المنصة ─────────────────────────────────
                Text(
                  branding.platformName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: branding.fontFamily,
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                // ── الـ Tagline ─────────────────────────────────
                if (branding.platformTagline.isNotEmpty)
                  Text(
                    branding.platformTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: branding.fontFamily,
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                    ),
                  ),

                const SizedBox(height: 40),

                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWidget(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) =>
            Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        placeholder: (_, __) =>
            Image.asset('assets/images/logo.png', fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
  }
}
