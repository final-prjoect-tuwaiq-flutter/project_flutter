import 'package:flutter/material.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseData().pushPlaceRequest(
        placeName: _nameController.text.trim(),
        location: _locationController.text.trim(),
        url: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال المكان للمراجعة')));
      _formKey.currentState!.reset();
      _nameController.clear();
      _locationController.clear();
      _websiteController.clear();
    } catch (error) {
      if (!mounted) return;
      final isUnauthenticated = error.toString().toLowerCase().contains(
        'authenticated',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUnauthenticated
                ? 'يجب تسجيل الدخول لإرسال مكان جديد'
                : 'تعذر إرسال المكان: $error',
          ),
          action: isUnauthenticated
              ? SnackBarAction(
                  label: 'تسجيل الدخول',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        appBar: AppBar(title: const Text('إضافة مكان')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'اقترح مكاناً جديداً',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('أدخل بيانات المكان ليتم مراجعته وإضافته.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المكان',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل اسم المكان'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  hintText: 'العنوان أو رابط الخريطة',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل موقع المكان'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط الموقع الإلكتروني (اختياري)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('إرسال المكان'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 1,
          onTap: _handleNavigation,
        ),
      ),
    );
  }
}
