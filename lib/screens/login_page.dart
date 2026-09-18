import 'package:flutter/material.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:project_flutter/widgets/auth_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_flutter/screens/sign_up_page.dart';

// ==========================================
// 1. الكنترولر الخاص بصفحة تسجيل الدخول
// ==========================================
class LoginController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool rememberMe = false;

  final SupabaseData _supabaseData = SupabaseData();

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    return null;
  }

  Future<bool> login(BuildContext context, VoidCallback updateUI) async {
    if (!formKey.currentState!.validate()) return false;

    isLoading = true;
    updateUI();

    try {
      await _supabaseData.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      isLoading = false;
      updateUI();
      return true;
    } on AuthException catch (e) {
      isLoading = false;
      updateUI();
      _showError(context, e.message);
      return false;
    } catch (e) {
      isLoading = false;
      updateUI();
      _showError(context, 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.');
      return false;
    }
  }

  void _showError(BuildContext context, String message) {
    // يعتمد الشكل والألوان على SnackBarTheme في theme.dart تلقائياً
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

// ==========================================
// 2. واجهة المستخدم (UI)
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _controller = LoginController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AuthLayout(
      title: 'حيّاك في المعزب',
      subtitle: 'سجل دخولك وتابع أماكنك المفضلة',
      child: Form(
        key: _controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل البريد الإلكتروني
            const AuthFieldLabel('البريد الإلكتروني'),
            TextFormField(
              controller: _controller.emailController,
              validator: _controller.validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),

            const SizedBox(height: 18),

            // حقل كلمة المرور
            const AuthFieldLabel('كلمة المرور'),
            TextFormField(
              controller: _controller.passwordController,
              validator: _controller.validatePassword,
              obscureText: !_controller.isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'أدخل كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _controller.isPasswordVisible
                      ? 'إخفاء كلمة المرور'
                      : 'إظهار كلمة المرور',
                  icon: Icon(
                    _controller.isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.isPasswordVisible =
                          !_controller.isPasswordVisible;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // تذكرني ونسيت كلمة المرور
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(
                    () => _controller.rememberMe = !_controller.rememberMe,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _controller.rememberMe,
                        onChanged: (val) {
                          setState(() => _controller.rememberMe = val ?? false);
                        },
                      ),
                      Text(
                        'تذكرني',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // زر تسجيل الدخول
            AppGradientButton(
              label: 'تسجيل الدخول',
              icon: Icons.arrow_forward_rounded,
              isLoading: _controller.isLoading,
              onPressed: _controller.isLoading
                  ? null
                  : () async {
                      bool success = await _controller.login(
                        context,
                        () => setState(() {}),
                      );
                      if (success && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        );
                      }
                    },
            ),

            const SizedBox(height: 28),

            // فاصل أو عبر
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'أو عبر',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),

            // أزرار التواصل الاجتماعي
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialButton(context, Icons.apple),
                const SizedBox(width: 14),
                _socialButton(
                  context,
                  Icons.g_mobiledata_rounded,
                  iconSize: 34,
                ),
                const SizedBox(width: 14),
                _socialButton(context, Icons.facebook),
              ],
            ),

            const SizedBox(height: 28),

            // رابط إنشاء الحساب
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ليس لديك حساب؟',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text('أنشئ حساباً'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // زر السوشيال ميديا
  Widget _socialButton(
    BuildContext context,
    IconData icon, {
    double iconSize = 24,
  }) {
    final colors = appColors(context);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Center(
        child: Icon(icon, color: colors.textPrimary, size: iconSize),
      ),
    );
  }
}
