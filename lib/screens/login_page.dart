import 'package:flutter/material.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
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
    if (value == null || value.trim().isEmpty)
      return 'الرجاء إدخال البريد الإلكتروني';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim()))
      return 'صيغة البريد الإلكتروني غير صحيحة';
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
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // الشعار والنص الترحيبي
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'مرحباً بك في المعزب!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 26,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سجل دخولك الآن وتابع أماكنك المفضلة',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // حقل البريد الإلكتروني
                  Text('البريد الإلكتروني', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller.emailController,
                    validator: _controller.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'أدخل بريدك الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // حقل كلمة المرور
                  Text('كلمة المرور', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller.passwordController,
                    validator: _controller.validatePassword,
                    obscureText: !_controller.isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'أدخل كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _controller.isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
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

                  const SizedBox(height: 12),

                  // تذكرني ونسيت كلمة المرور
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _controller.rememberMe,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(
                                () => _controller.rememberMe = val ?? false,
                              );
                            },
                          ),
                          Text('تذكرني', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // زر تسجيل الدخول
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: AppTheme.blackCtaButtonStyle,
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
                      child: _controller.isLoading
                          ? CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                            )
                          : Text(
                              'تسجيل الدخول',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // فاصل أو عبر
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('أو عبر', style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // أزرار التواصل الاجتماعي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialButton(context, Icons.apple),
                      const SizedBox(width: 16),
                      _socialButton(
                        context,
                        Icons.g_mobiledata_rounded,
                        iconSize: 36,
                      ),
                      const SizedBox(width: 16),
                      _socialButton(context, Icons.facebook),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // رابط إنشاء الحساب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ليس لديك حساب؟', style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          'سجل الآن',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت زر السوشيال ميديا - ألوانه من الثيم
  Widget _socialButton(
    BuildContext context,
    IconData icon, {
    double iconSize = 24,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Icon(icon, color: theme.colorScheme.onSurface, size: iconSize),
      ),
    );
  }
}
