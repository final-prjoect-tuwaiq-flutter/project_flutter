import 'package:flutter/material.dart';
import 'package:project_flutter/screens/home_shell.dart';
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
  bool isSendingReset = false;

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

    // يُلتقط قبل أي await، فيبقى صالحاً حتى لو زالت الشاشة أثناء الطلب.
    final messenger = ScaffoldMessenger.of(context);

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
      _showMessage(messenger, e.message);
      return false;
    } catch (e) {
      isLoading = false;
      updateUI();
      _showMessage(messenger, 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.');
      return false;
    }
  }

  /// إرسال رابط إعادة تعيين كلمة المرور إلى بريد المستخدم.
  /// كان الزر سابقاً بلا أي سلوك، فيبقى من نسي كلمته عالقاً بلا مخرج.
  Future<void> sendPasswordReset(
    BuildContext context,
    VoidCallback updateUI,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = emailController.text.trim();

    // إعادة التعيين تحتاج بريداً صالحاً، فنتحقق منه وحده دون بقية الحقول.
    final emailError = validateEmail(email);
    if (emailError != null) {
      _showMessage(
        messenger,
        'أدخل بريدك الإلكتروني أولاً لإرسال رابط الاستعادة',
      );
      return;
    }

    isSendingReset = true;
    updateUI();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showMessage(messenger, 'أرسلنا رابط إعادة تعيين كلمة المرور إلى $email');
    } on AuthException catch (e) {
      _showMessage(messenger, e.message);
    } catch (_) {
      _showMessage(messenger, 'تعذر إرسال رابط الاستعادة. حاول لاحقاً.');
    } finally {
      isSendingReset = false;
      updateUI();
    }
  }

  void _showMessage(ScaffoldMessengerState messenger, String message) {
    // يعتمد الشكل والألوان على SnackBarTheme في theme.dart تلقائياً
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

            // الجلسة محفوظة تلقائياً في Supabase، فلا حاجة لخيار "تذكرني"
            // كان موجوداً بلا أي أثر فعلي على بقاء تسجيل الدخول.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _controller.isSendingReset
                    ? null
                    : () => _controller.sendPasswordReset(
                        context,
                        () => setState(() {}),
                      ),
                child: Text(
                  _controller.isSendingReset
                      ? 'جارٍ الإرسال…'
                      : 'نسيت كلمة المرور؟',
                ),
              ),
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
                        // pushReplacement كان يضع صفحة رئيسية ثانية فوق
                        // الأولى ويفقد المستخدم الشاشة التي جاء منها
                        // (تفاصيل مكان، المفضلة، الحساب...). الرجوع يُعيده
                        // إلى حيث كان، وقد صار مسجّلاً دخوله.
                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.pop(true);
                        } else {
                          navigator.pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeShell(),
                            ),
                          );
                        }
                      }
                    },
            ),

            // أزرار "أو عبر" (آبل/جوجل/فيسبوك) أُزيلت: لم تكن موصولة بأي
            // مزوّد OAuth، فكان المستخدم يضغطها ولا يحدث شيء. تُعاد عند
            // تفعيل المزوّدين فعلياً في Supabase.
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
}
