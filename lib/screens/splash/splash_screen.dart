import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/ltmo_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 800));

      // Check for an existing valid session (secure-storage token) before
      // deciding where to go - this also (re)syncs local notifications for
      // an already-logged-in session that's just being resumed/relaunched.
      await ref.read(userProvider.notifier).fetchCurrentUser();

      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      context.go(user != null ? '/' : '/login');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LtmoColors.encre,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/ltmo-mark-light.svg',
                  width: 96,
                  height: 96,
                ),
                const SizedBox(height: 24),
                Text(
                  'LTMO',
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                    color: LtmoColors.creme,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Let's try to make one",
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
                    color: LtmoColors.creme.withOpacity(0.6),
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
