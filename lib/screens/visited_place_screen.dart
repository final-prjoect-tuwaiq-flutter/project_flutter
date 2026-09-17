import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';

class VisitedPlaceScreen extends StatefulWidget {
  final Event event;

  const VisitedPlaceScreen({super.key, required this.event});

  @override
  State<VisitedPlaceScreen> createState() => _VisitedPlaceScreenState();
}

class _VisitedPlaceScreenState extends State<VisitedPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _visitedAt = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _setDate(DateTime date) {
    setState(() => _visitedAt = DateTime(date.year, date.month, date.day));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _visitedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (date != null) _setDate(date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseData().addVisitedPlace(
        placeId: widget.event.id,
        notes: _notesController.text.trim(),
        visitedAt: _visitedAt,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final isUnauthenticated = error.toString().toLowerCase().contains(
        'authenticated',
      );
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(
                  child: Text(
                    isUnauthenticated
                        ? 'يجب تسجيل الدخول لحفظ الزيارة'
                        : 'تعذر حفظ الزيارة: $error',
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (isUnauthenticated)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amberAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'تسجيل الدخول الآن',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) messenger.hideCurrentSnackBar();
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تسجيل زيارة ${widget.event.title ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظاتك',
                    hintText: 'اكتب ملاحظاتك عن المكان',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل ملاحظة واحدة على الأقل'
                      : null,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'تاريخ الزيارة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('اليوم'),
                      selected: _isSameDay(_visitedAt, DateTime.now()),
                      onSelected: (_) => _setDate(DateTime.now()),
                    ),
                    ChoiceChip(
                      label: const Text('أمس'),
                      selected: _isSameDay(
                        _visitedAt,
                        DateTime.now().subtract(const Duration(days: 1)),
                      ),
                      onSelected: (_) => _setDate(
                        DateTime.now().subtract(const Duration(days: 1)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(_formatDate(_visitedAt)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ الزيارة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
