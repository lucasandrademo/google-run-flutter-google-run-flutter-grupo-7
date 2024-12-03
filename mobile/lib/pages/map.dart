import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'list.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapController _mapController;
  LatLng? _currentLocation;
  LatLng? _lastRequestLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _determinePosition();
    _listenToPositionChanges();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desativado. Ative o GPS.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permissão de localização negada permanentemente. Ative nas configurações.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, 16.0);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _listenToPositionChanges() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLocation;
      });

      _mapController.move(newLocation, 16.0);

      if (_lastRequestLocation == null ||
          Geolocator.distanceBetween(
                _lastRequestLocation!.latitude,
                _lastRequestLocation!.longitude,
                newLocation.latitude,
                newLocation.longitude,
              ) >=
              100) {
        _lastRequestLocation = newLocation;
        _makeRequest(newLocation);
      }
    });
  }

  Future<void> _makeRequest(LatLng location) async {
    final url =
        'https://southamerica-east1-dev-distr.cloudfunctions.net/gps-puc/getNearbyPucMinas?lat=${location.latitude}&long=${location.longitude}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is List && data.isNotEmpty) {
          final unidade = data[0];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bem vindo à PUC Minas unidade $unidade'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception('Erro ao fazer a requisição: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa - Localização Atual'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? LatLng(0, 0),
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 36.0,
                        height: 36.0,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 36.0,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListPage()),
          );
        },
        child: const Icon(Icons.list),
      ),
    );
  }
}
