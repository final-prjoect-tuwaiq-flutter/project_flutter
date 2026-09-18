import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:project_flutter/model/partner_account.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// يحتفظ بحالة حساب الشريك للمستخدم الحالي حتى تعرفها كل الشاشات
/// (صفحة الحساب تعرض الحالة، وصفحة الإضافة تفتح النشر المباشر للمعتمدين).
class PartnerController extends ChangeNotifier {
  PartnerController._() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      _account = null;
      _loaded = false;
      notifyListeners();
      if (state.session != null) unawaited(ensureLoaded());
    });
  }

  static final PartnerController instance = PartnerController._();

  final SupabaseData _data = SupabaseData();
  late final StreamSubscription<AuthState> _authSubscription;

  PartnerAccount? _account;
  bool _loaded = false;
  Future<void>? _loading;

  PartnerAccount? get account => _account;

  bool get isLoaded => _loaded;

  /// الشرط الوحيد الذي يسمح بنشر مكان مباشرة بدون مراجعة.
  bool get canPublishDirectly => _account?.isApproved ?? false;

  bool get _isSignedIn => Supabase.instance.client.auth.currentUser != null;

  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> refresh() {
    _loaded = false;
    return ensureLoaded();
  }

  Future<void> _load() async {
    if (!_isSignedIn) {
      _account = null;
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      _account = await _data.fetchPartnerAccount();
    } catch (error) {
      // يحدث مثلاً قبل تطبيق migration جدول partner_accounts.
      debugPrint('تعذر تحميل حالة حساب الشريك: $error');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<PartnerAccount> submit({
    required PartnerRole role,
    required String displayName,
    String? contactPhone,
    String? website,
    String? notes,
  }) async {
    final account = await _data.submitPartnerApplication(
      role: role,
      displayName: displayName,
      contactPhone: contactPhone,
      website: website,
      notes: notes,
    );

    _account = account;
    _loaded = true;
    notifyListeners();
    return account;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
