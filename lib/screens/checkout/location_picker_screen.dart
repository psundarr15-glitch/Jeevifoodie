import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class PickedLocation {
  final double lat;
  final double lng;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  PickedLocation({
    required this.lat,
    required this.lng,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
  });
}

/// Lets the person drag the map to pin their exact delivery spot, then
/// reverse-geocodes that point (via OpenStreetMap's free Nominatim API -
/// no separate key needed, and no Google Maps key needed either, since
/// the map itself is rendered with flutter_map + OSM tiles) to fill in
/// the address fields automatically. Those fields stay editable
/// afterwards - this is a starting point, not the final word, since
/// reverse geocoding can be imprecise for new buildings or rural addresses.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(13.0827, 80.2707); // Chennai, sensible default
  bool _locating = false;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw AppLocalizations.of(context)!.turnOnLocationServices;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw AppLocalizations.of(context)!.locationPermissionNeeded;
      }
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = target);
      _mapController.move(target, 16);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      // Nominatim's usage policy requires a descriptive User-Agent and
      // caps free usage at ~1 request/second - fine for a single tap here.
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${_center.latitude}&lon=${_center.longitude}',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'JeeviFoodieApp/1.0'});
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = (body['address'] as Map<String, dynamic>?) ?? {};

      final road = addr['road']?.toString() ?? '';
      final suburb = addr['suburb']?.toString() ?? addr['neighbourhood']?.toString() ?? '';
      final addressLine = [road, suburb].where((s) => s.isNotEmpty).join(', ');
      final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '').toString();
      final state = (addr['state'] ?? '').toString();
      final pincode = (addr['postcode'] ?? '').toString();

      if (!mounted) return;
      Navigator.of(context).pop(PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        addressLine: addressLine.isNotEmpty ? addressLine : (body['display_name']?.toString() ?? ''),
        city: city,
        state: state,
        pincode: pincode,
      ));
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.couldntLookUpAddress);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.pinYourLocation)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) _center = pos.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodexpress.customer_app',
              ),
            ],
          ),
          // Fixed center pin - the map moves underneath it, which is the
          // standard "drag map to place pin" pattern and avoids the pin
          // lagging behind drag gestures.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_pin, size: 44, color: AppTheme.primary),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton(
              heroTag: 'use-current-location',
              backgroundColor: Colors.white,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: AppTheme.primary),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 12.5)),
                  ),
                ElevatedButton(
                  onPressed: _resolving ? null : _confirm,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _resolving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.useThisLocation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
