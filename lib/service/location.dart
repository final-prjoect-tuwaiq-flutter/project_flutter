import 'package:geolocator/geolocator.dart';

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 10),
  );

  try {
    return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
  } catch (e) {
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      return lastKnown;
    }
    rethrow;
  }
}
double distance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
  double distanceInMeters = Geolocator.distanceBetween(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );
  return (distanceInMeters * 100).round() / 100;
}
