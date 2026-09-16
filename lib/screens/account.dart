import 'package:flutter/material.dart';
import 'package:project_flutter/screens/auth_test.dart';
import 'package:project_flutter/screens/test.dart';
import 'package:project_flutter/pages/categories_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isSigningOut = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _openAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthTestScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    setState(() {
      _isSigningOut = true;
    });
    try {
      await _supabase.auth.signOut();
      if (mounted) setState(() {});
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final isSignedIn = user != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
            children: [
              const Text(
                'حسابي',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E24),
                ),
              ),
              const SizedBox(height: 18),
              _AccountHeader(
                user: user,
                onPressed: isSignedIn ? null : _openAuth,
              ),
              const SizedBox(height: 24),
              const _SectionLabel(label: 'اختصاراتي'),
              const SizedBox(height: 8),
              _AccountTile(
                icon: Icons.favorite_rounded,
                title: 'مفضلتي',
                subtitle: 'الفعاليات التي حفظتها',
                color: const Color(0xFFFF4B6E),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TestScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AccountTile(
                icon: Icons.notifications_none_rounded,
                title: 'التنبيهات',
                subtitle: 'ستظهر هنا تنبيهاتك قريباً',
                color: const Color(0xFF4E8DFF),
                onTap: () => _showComingSoon(context),
              ),
              const SizedBox(height: 12),
              _AccountTile(
                icon: Icons.settings_outlined,
                title: 'الإعدادات',
                subtitle: 'تخصيص تجربتك في التطبيق',
                color: const Color(0xFF7B61FF),
                onTap: () => _showComingSoon(context),
              ),
              if (isSignedIn) ...[
                const SizedBox(height: 28),
                const _SectionLabel(label: 'الحساب'),
                const SizedBox(height: 8),
                _AccountTile(
                  icon: Icons.logout_rounded,
                  title: 'تسجيل الخروج',
                  subtitle: 'الخروج من هذا الجهاز',
                  color: const Color(0xFF1E1E24),
                  isLoading: _isSigningOut,
                  onTap: _isSigningOut ? null : _signOut,
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: _AccountBottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            }
          },
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة ستتوفر قريباً')),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final User? user;
  final VoidCallback? onPressed;

  const _AccountHeader({required this.user, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = user != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFF4B6E),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSignedIn ? 'مرحباً بعودتك' : 'أهلاً بك',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignedIn ? user!.email ?? '' : 'سجل الدخول لحفظ مفضلاتك',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!isSignedIn)
            TextButton(
              onPressed: onPressed,
              child: const Text(
                'دخول',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E1E24),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AccountBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem(0, Icons.home_rounded, 'الرئيسية'),
          _buildItem(1, Icons.explore_rounded, 'استكشف'),
          _buildItem(2, Icons.calendar_today_rounded, 'الفعاليات'),
          _buildItem(3, Icons.person_rounded, 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4B6E) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}