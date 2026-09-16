import 'package:flutter/material.dart';
import 'package:project_flutter/service/location.dart';
import 'package:geolocator/geolocator.dart';


class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
  late final Future<Position> _positionsFuture;

  @override
  void initState() {
    super.initState();
    _positionsFuture = determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('Test Screen')),
      body: Center(
        child: FutureBuilder<Position>(
          future: _positionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Location error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Text('No location found');
            }

            final position = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${position.latitude}, ${position.longitude}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  '${distance(position.latitude, position.longitude, 24.74308630182212, 46.65657791837819)} meters',
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}