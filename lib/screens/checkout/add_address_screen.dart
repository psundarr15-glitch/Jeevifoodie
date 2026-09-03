import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

enum _AddressLabelKind { home, work, other }

/// Single-screen "Add New Address": drag-to-pin map at the top (reverse
/// geocoded live, same free OpenStreetMap/Nominatim lookup the old
/// two-step flow used — no Google Maps key needed), Label As chips,
/// contact person details (defaulted from the logged-in profile),
/// then the finer address fields, all under one "Save Location" button.
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  _AddressLabelKind _labelKind = _AddressLabelKind.home;
  final _addressLine = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _streetNumber = TextEditingController();
  final _house = TextEditingController();
  final _floor = TextEditingController();

  // Kept but not shown as separate fields (screenshot only shows the
  // combined "Delivery Address" line) — still required by the backend,
  // so we fill them from the same reverse-geocode lookup.
  String _city = '';
  String _state = '';
  String _pincode = '';

  LatLng _center = const LatLng(13.0827, 80.2707); // Chennai, sensible default
  bool _locating = false;
  bool _resolving = false;
  bool _saving = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _contactName.text = (user?['name'] as String?) ?? '';
    _contactPhone.text = (user?['phone'] as String?) ?? '';
    _useCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressLine.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _streetNumber.dispose();
    _house.dispose();
    _floor.dispose();
    super.dispose();
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
      await _reverseGeocode();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _reverseGeocode() async {
    setState(() => _resolving = true);
    try {
      // Nominatim's usage policy requires a descriptive User-Agent and
      // caps free usage at ~1 request/second - fine for a single lookup
      // per drag-end here.
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${_center.latitude}&lon=${_center.longitude}',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'JeeviFoodieApp/1.0'});
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = (body['address'] as Map<String, dynamic>?) ?? {};

      final road = addr['road']?.toString() ?? '';
      final suburb = addr['suburb']?.toString() ?? addr['neighbourhood']?.toString() ?? '';
      final line = [road, suburb].where((s) => s.isNotEmpty).join(', ');

      if (!mounted) return;
      setState(() {
        _addressLine.text = line.isNotEmpty ? line : (body['display_name']?.toString() ?? '');
        _city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '').toString();
        _state = (addr['state'] ?? '').toString();
        _pincode = (addr['postcode'] ?? '').toString();
      });
    } catch (_) {
      // Silent - the address line stays editable either way, this is
      // just a head start.
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  String get _labelText {
    switch (_labelKind) {
      case _AddressLabelKind.home:
        return 'Home';
      case _AddressLabelKind.work:
        return 'Work';
      case _AddressLabelKind.other:
        return 'Other';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_city.isEmpty || _state.isEmpty || _pincode.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.couldntLookUpAddress);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ProfileService.addAddress(
        label: _labelText,
        contactName: _contactName.text.trim(),
        contactPhone: _contactPhone.text.trim(),
        addressLine: _addressLine.text.trim(),
        streetNumber: _streetNumber.text.trim(),
        house: _house.text.trim(),
        floor: _floor.text.trim(),
        city: _city,
        state: _state,
        pincode: _pincode,
        lat: _center.latitude,
        lng: _center.longitude,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _labelChip(_AddressLabelKind kind, IconData icon) {
    final selected = _labelKind == kind;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _labelKind = kind),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
            border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: selected ? AppTheme.primary : Colors.grey.shade500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.addAddress)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 220,
                decoration: BoxDecoration(border: Border.all(color: AppTheme.primary, width: 1.5)),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 16,
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture) {
                            _center = pos.center;
                            // Debounce - wait until the drag settles
                            // before firing a reverse-geocode lookup,
                            // instead of one per frame while dragging.
                            _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 700), _reverseGeocode);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.foodexpress.customer_app',
                        ),
                      ],
                    ),
                    // Fixed center pin with a "PICK" flag - the map moves
                    // underneath it, which is the standard "drag map to
                    // place pin" pattern and avoids the pin lagging
                    // behind drag gestures.
                    IgnorePointer(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                child: const Text('PICK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const Icon(Icons.location_pin, size: 36, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: FloatingActionButton.small(
                        heroTag: 'use-current-location',
                        backgroundColor: Colors.white,
                        onPressed: _locating ? null : _useCurrentLocation,
                        child: _locating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location, color: AppTheme.primary, size: 20),
                      ),
                    ),
                    if (_resolving)
                      const Positioned(
                        top: 10,
                        left: 10,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Add the location Correctly', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ),
            const SizedBox(height: 18),

            Text(t.labelHomeWork.split(' (').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                _labelChip(_AddressLabelKind.home, Icons.home_outlined),
                _labelChip(_AddressLabelKind.work, Icons.work_outline),
                _labelChip(_AddressLabelKind.other, Icons.apps),
              ],
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _addressLine,
              decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder()),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().length < 5) ? t.enterCompleteAddress : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _contactName,
              decoration: const InputDecoration(labelText: 'Contact Person Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 2) ? t.validatorRequired : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Contact Person Number',
                border: OutlineInputBorder(),
                prefixText: '🇮🇳 +91  ',
              ),
              validator: (v) => (v == null || !RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) ? t.validatorRequired : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _streetNumber,
              decoration: const InputDecoration(labelText: 'Street Number (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _house,
                    decoration: const InputDecoration(labelText: 'House (Optional)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _floor,
                    decoration: const InputDecoration(labelText: 'Floor (Optional)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.my_location, color: Colors.white, size: 18),
                label: Text(t.saveAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
