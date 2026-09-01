import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import 'location_picker_screen.dart';
import '../../l10n/app_localizations.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Home');
  final _addressLine = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  bool _isDefault = false;
  bool _saving = false;
  String? _error;
  double? _lat;
  double? _lng;

  // Matches the backend's validation (ProfileApiController::addAddress) so
  // obviously wrong/garbage entries get caught immediately instead of
  // round-tripping to the server first.
  static final _nameLikePattern = RegExp(r"^[A-Za-z\u00C0-\u024F\s.'-]+$");

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (picked == null) return;
    setState(() {
      _lat = picked.lat;
      _lng = picked.lng;
      if (picked.addressLine.isNotEmpty) _addressLine.text = picked.addressLine;
      if (picked.city.isNotEmpty) _city.text = picked.city;
      if (picked.state.isNotEmpty) _state.text = picked.state;
      if (picked.pincode.isNotEmpty) _pincode.text = picked.pincode;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ProfileService.addAddress(
        label: _label.text.trim(),
        addressLine: _addressLine.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        pincode: _pincode.text.trim(),
        lat: _lat,
        lng: _lng,
        isDefault: _isDefault,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.addAddress)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              OutlinedButton.icon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(_lat == null ? t.selectOnMap : t.locationPinnedTapToChange),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _label,
                decoration: InputDecoration(labelText: t.labelHomeWork),
                validator: (v) => (v == null || v.trim().length < 2) ? t.validatorRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressLine,
                decoration: InputDecoration(labelText: t.addressLine),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().length < 5) ? t.enterCompleteAddress : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                decoration: InputDecoration(labelText: t.city),
                validator: (v) {
                  if (v == null || v.trim().length < 2) return t.validatorRequired;
                  if (!_nameLikePattern.hasMatch(v.trim())) return t.enterValidCityName;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _state,
                decoration: InputDecoration(labelText: t.state),
                validator: (v) {
                  if (v == null || v.trim().length < 2) return t.validatorRequired;
                  if (!_nameLikePattern.hasMatch(v.trim())) return t.enterValidStateName;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincode,
                decoration: InputDecoration(labelText: t.pincode),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) => (v == null || !RegExp(r'^[0-9]{6}$').hasMatch(v.trim())) ? t.enterValid6DigitPincode : null,
              ),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                title: Text(t.setAsDefaultAddress),
                contentPadding: EdgeInsets.zero,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t.saveAddress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
