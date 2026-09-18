import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// يُرمى عند محاولة تعديل المفضلة بدون تسجيل دخول.
class NotSignedInException implements Exception {
  const NotSignedInException();
}

/// مصدر واحد لحالة المفضلة في التطبيق كله، حتى يبقى زر القلب في الكروت
/// وصفحة التفاصيل وصفحة المفضلة متطابقاً دائماً.
class FavoritesController extends ChangeNotifier {
  FavoritesController._() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.session == null) {
        _ids = <int>{};
        _loaded = false;
        notifyListeners();
      } else {
        _loaded = false;
        unawaited(ensureLoaded());
      }
    });
  }

  static final FavoritesController instance = FavoritesController._();

  final SupabaseData _data = SupabaseData();
  late final StreamSubscription<AuthState> _authSubscription;

  Set<int> _ids = <int>{};
  bool _loaded = false;
  Future<void>? _loading;

  Set<int> get ids => Set<int>.unmodifiable(_ids);

  bool get isLoaded => _loaded;

  bool isFavorite(int placeId) => _ids.contains(placeId);

  bool get _isSignedIn => Supabase.instance.client.auth.currentUser != null;

  /// يجلب المفضلة مرة واحدة فقط، ويشارك نفس الطلب مع كل من ينتظره.
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
      _ids = <int>{};
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      final favorites = await _data.fetchFavorites();
      _ids = favorites.toSet();
    } catch (error) {
      // الفشل لا يمنع استخدام التطبيق، ويمكن إعادة المحاولة عبر refresh().
      debugPrint('تعذر تحميل المفضلة: $error');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// يبدّل حالة المكان مع تحديث متفائل، ويتراجع عند فشل الطلب.
  /// يُرجع الحالة الجديدة، ويرمي [NotSignedInException] للزائر غير المسجّل.
  Future<bool> toggle(int placeId) async {
    if (!_isSignedIn) throw const NotSignedInException();

    final wasFavorite = _ids.contains(placeId);
    _setLocal(placeId, !wasFavorite);

    try {
      if (wasFavorite) {
        await _data.removeFavorite(placeId);
      } else {
        await _data.addFavorite(placeId);
      }
      return !wasFavorite;
    } catch (_) {
      _setLocal(placeId, wasFavorite);
      rethrow;
    }
  }

  /// إزالة مباشرة (تُستخدم في صفحة المفضلة حيث يختفي الكرت بعد الإزالة).
  Future<void> remove(int placeId) async {
    if (!_ids.contains(placeId)) return;
    _setLocal(placeId, false);

    try {
      await _data.removeFavorite(placeId);
    } catch (_) {
      _setLocal(placeId, true);
      rethrow;
    }
  }

  void _setLocal(int placeId, bool isFavorite) {
    if (isFavorite) {
      _ids.add(placeId);
    } else {
      _ids.remove(placeId);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
