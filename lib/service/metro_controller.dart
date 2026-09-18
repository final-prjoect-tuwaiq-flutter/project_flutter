import 'package:flutter/foundation.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/model/metro_station.dart';
import 'package:project_flutter/service/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// نطاق المشي المعتمد لاعتبار المكان "قريباً من المترو".
const double kMetroWalkRadiusMeters = 850;

/// يحمّل محطات المترو مرة واحدة ويحسب قرب الأماكن منها محلياً.
/// عدد المحطات صغير، فتحميلها كاملة أرخص من استعلام لكل مكان.
class MetroController extends ChangeNotifier {
  MetroController._();

  static final MetroController instance = MetroController._();

  List<MetroStation> _stations = const [];
  bool _loaded = false;
  Future<void>? _loading;

  /// ذاكرة نتائج لكل مكان، فقائمة الأماكن تعيد البناء كثيراً أثناء التمرير.
  final Map<int, MetroAccess?> _accessCache = {};

  List<MetroStation> get stations => List.unmodifiable(_stations);

  bool get isLoaded => _loaded;

  bool get hasStations => _stations.isNotEmpty;

  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final response = await Supabase.instance.client
          .from('metro_stations')
          .select('station_code, station_name, line_name, lat, lng');

      _stations = response
          .map((json) => MetroStation.tryFromJson(Map<String, dynamic>.from(json)))
          .whereType<MetroStation>()
          .toList();
    } catch (error) {
      // غياب الجدول أو منع القراءة يعني ببساطة إخفاء ميزة المترو.
      debugPrint('تعذر تحميل محطات المترو: $error');
    } finally {
      _loaded = true;
      _accessCache.clear();
      notifyListeners();
    }
  }

  /// يُرجع null إذا لم تُحمّل المحطات بعد، أو كان المكان بلا إحداثيات.
  MetroAccess? accessForEvent(Event event) {
    if (event.lat == null || event.lng == null) return null;

    return _accessCache.putIfAbsent(
      event.id,
      () => accessForPoint(event.lat!, event.lng!),
    );
  }

  MetroAccess? accessForPoint(double lat, double lng) {
    if (_stations.isEmpty) return null;

    final measured = <NearbyStation>[];
    for (final station in _stations) {
      measured.add(
        NearbyStation(
          station: station,
          distanceMeters: distance(lat, lng, station.lat, station.lng),
        ),
      );
    }

    measured.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return MetroAccess(
      nearest: measured.first,
      withinWalk: measured
          .where((entry) => entry.distanceMeters <= kMetroWalkRadiusMeters)
          .toList(),
    );
  }
}
