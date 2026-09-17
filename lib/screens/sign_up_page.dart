import 'package:flutter/material.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. الكنترولر الخاص بصفحة التسجيل
// ==========================================
class SignUpController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final SupabaseData _supabaseData = SupabaseData();

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
    if (value.length < 6) return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (value != passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  Future<bool> signUp(BuildContext context, VoidCallback updateUI) async {
    if (!formKey.currentState!.validate()) return false;

    isLoading = true;
    updateUI();

    try {
      await _supabaseData.signUp(
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
      _showError(context, 'حدث خطأ غير متوقع أثناء التسجيل.');
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
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final SignUpController _controller = SignUpController();

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
        appBar: AppBar(leading: const SizedBox.shrink()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الشعار والنص الترحيبي
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'أنشئ حسابك في المعزب',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 26,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سجل الآن وابدأ تجربتك الممتعة!',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // حقل الإيميل
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
                      hintText: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _controller.isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () => setState(
                          () => _controller.isPasswordVisible =
                              !_controller.isPasswordVisible,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // حقل تأكيد كلمة المرور
                  Text('تأكيد كلمة المرور', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller.confirmPasswordController,
                    validator: _controller.validateConfirmPassword,
                    obscureText: !_controller.isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'أعد إدخال كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _controller.isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () => setState(
                          () => _controller.isConfirmPasswordVisible =
                              !_controller.isConfirmPasswordVisible,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // زر إنشاء الحساب
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: AppTheme.blackCtaButtonStyle,
                      onPressed: _controller.isLoading
                          ? null
                          : () async {
                              bool success = await _controller.signUp(
                                context,
                                () => setState(() {}),
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إنشاء الحساب بنجاح!'),
                                  ),
                                );
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
                              'إنشاء الحساب',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // رابط تسجيل الدخول
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب بالفعل؟',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          'سجل دخول الآن',
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
