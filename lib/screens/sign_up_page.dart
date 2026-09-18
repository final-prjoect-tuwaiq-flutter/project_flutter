import 'package:flutter/material.dart';
import 'package:project_flutter/screens/home_shell.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:project_flutter/widgets/auth_layout.dart';
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
    if (value.length < 6) return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (value != passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  /// نتيجة التسجيل: هل نجح، وهل صار المستخدم مسجّل الدخول فعلاً.
  ///
  /// حين يكون تأكيد البريد مفعّلاً في Supabase يعود الطلب بلا جلسة،
  /// فالحساب أُنشئ لكن المستخدم ليس داخل التطبيق بعد.
  Future<({bool ok, bool signedIn})> signUp(
    BuildContext context,
    VoidCallback updateUI,
  ) async {
    if (!formKey.currentState!.validate()) {
      return (ok: false, signedIn: false);
    }

    // يُلتقط قبل أي await، فيبقى صالحاً حتى لو زالت الشاشة أثناء الطلب.
    final messenger = ScaffoldMessenger.of(context);

    isLoading = true;
    updateUI();

    try {
      final response = await _supabaseData.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      isLoading = false;
      updateUI();
      return (ok: true, signedIn: response.session != null);
    } on AuthException catch (e) {
      isLoading = false;
      updateUI();
      _showError(messenger, e.message);
      return (ok: false, signedIn: false);
    } catch (e) {
      isLoading = false;
      updateUI();
      _showError(messenger, 'حدث خطأ غير متوقع أثناء التسجيل.');
      return (ok: false, signedIn: false);
    }
  }

  void _showError(ScaffoldMessengerState messenger, String message) {
    // يعتمد الشكل والألوان على SnackBarTheme في theme.dart تلقائياً
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    final colors = appColors(context);

    return AuthLayout(
      title: 'أنشئ حسابك في المعزب',
      subtitle: 'سجل الآن وابدأ تجربتك الممتعة!',
      child: Form(
        key: _controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل الإيميل
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
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: '6 أحرف على الأقل',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _controller.isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () => setState(
                    () => _controller.isPasswordVisible =
                        !_controller.isPasswordVisible,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // حقل تأكيد كلمة المرور
            const AuthFieldLabel('تأكيد كلمة المرور'),
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
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () => setState(
                    () => _controller.isConfirmPasswordVisible =
                        !_controller.isConfirmPasswordVisible,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // زر إنشاء الحساب
            AppGradientButton(
              label: 'إنشاء الحساب',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _controller.isLoading,
              onPressed: _controller.isLoading
                  ? null
                  : () async {
                      final result = await _controller.signUp(
                        context,
                        () => setState(() {}),
                      );
                      if (!result.ok || !context.mounted) return;

                      // بلا جلسة يعني أن Supabase ينتظر تأكيد البريد؛
                      // إدخاله للتطبيق هنا كان يوهمه بأنه مسجّل دخوله
                      // ثم تفشل عليه المفضلة وإضافة الأماكن بلا سبب واضح.
                      if (!result.signedIn) {
                        await showDialog<void>(
                          context: context,
                          builder: (dialogContext) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              icon: const AppIconMedallion(
                                icon: Icons.mark_email_unread_rounded,
                                size: 56,
                              ),
                              title: const Text('أكّد بريدك الإلكتروني'),
                              content: Text(
                                'أرسلنا رابط تفعيل إلى '
                                '${_controller.emailController.text.trim()}\n\n'
                                'افتح الرابط ثم عُد لتسجيل الدخول.',
                                textAlign: TextAlign.center,
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('حسناً'),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إنشاء الحساب بنجاح!')),
                      );

                      // الرجوع لما كان يفعله المستخدم قبل التسجيل بدل
                      // تكديس صفحة رئيسية ثانية فوق الأولى.
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop(true);
                      } else {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeShell()),
                        );
                      }
                    },
            ),

            const SizedBox(height: 24),

            // رابط تسجيل الدخول
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لديك حساب بالفعل؟',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('سجل دخولك'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
