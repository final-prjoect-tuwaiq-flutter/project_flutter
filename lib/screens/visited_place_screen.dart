import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';

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
            content: Text(
              isUnauthenticated
                  ? 'يجب تسجيل الدخول لحفظ الزيارة'
                  : 'تعذر حفظ الزيارة: $error',
              maxLines: 2,
            ),
            duration: const Duration(seconds: 3),
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
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) messenger.hideCurrentSnackBar();
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final isCustomDate =
        !_isSameDay(_visitedAt, DateTime.now()) &&
        !_isSameDay(_visitedAt, yesterday);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ترويسة الحوار
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 14, 20),
                  decoration: BoxDecoration(gradient: colors.inkGradient),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          gradient: colors.accentGradient,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل زيارة',
                                style: AppTheme.display(
                                  20,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              Text(
                                widget.event.title ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.goldColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppCircleButton(
                        icon: Icons.close_rounded,
                        tooltip: 'إغلاق',
                        size: 36,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FormLabel(text: 'ملاحظاتك'),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'ما الذي أعجبك؟ نصائح لمن سيزوره بعدك',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'أدخل ملاحظة واحدة على الأقل'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _FormLabel(text: 'تاريخ الزيارة'),
                      Row(
                        children: [
                          _DateOption(
                            label: 'اليوم',
                            selected: _isSameDay(_visitedAt, DateTime.now()),
                            onTap: () => _setDate(DateTime.now()),
                          ),
                          const SizedBox(width: 8),
                          _DateOption(
                            label: 'أمس',
                            selected: _isSameDay(_visitedAt, yesterday),
                            onTap: () => _setDate(yesterday),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateOption(
                              label: isCustomDate
                                  ? formatArabicDate(_visitedAt)
                                  : 'تاريخ آخر',
                              icon: Icons.calendar_month_rounded,
                              selected: isCustomDate,
                              onTap: _pickDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppGradientButton(
                        label: 'حفظ الزيارة',
                        icon: Icons.check_rounded,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _save,
                        height: 52,
                      ),
                    ],
                  ),
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
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        text,
        style: TextStyle(
          color: appColors(context).textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _DateOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? colors.accentColorSoft : colors.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.accentColor : colors.borderSoft,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? colors.accentColor : colors.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? colors.accentColor : colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
