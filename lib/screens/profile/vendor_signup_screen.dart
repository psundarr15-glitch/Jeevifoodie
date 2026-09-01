import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/file_picker_field.dart';
import '../checkout/location_picker_screen.dart';

class VendorSignupScreen extends StatefulWidget {
  const VendorSignupScreen({super.key});
  @override
  State<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends State<VendorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _restaurantName = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _managerEmail = TextEditingController();
  final _managerPassword = TextEditingController();
  final _restaurantPhone = TextEditingController();
  final _address = TextEditingController();
  double? _lat;
  double? _lng;
  final _restaurantType = TextEditingController();
  String _foodType = 'both';
  final _fssaiNumber = TextEditingController();
  final _tinNumber = TextEditingController();
  final _description = TextEditingController();
  final _costForTwo = TextEditingController();

  final _bankAccountNumber = TextEditingController();
  final _bankIfsc = TextEditingController();
  final _bankAccountHolder = TextEditingController();

  File? _banner;
  File? _logo;
  File? _fssaiCertificate;
  File? _tinCertificate;

  bool _saving = false;
  String? _error;

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (picked == null) return;
    setState(() {
      _lat = picked.lat;
      _lng = picked.lng;
      if (_address.text.trim().isEmpty && picked.addressLine.isNotEmpty) {
        _address.text = picked.addressLine;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      setState(() => _error = AppLocalizations.of(context)!.pleasePinRestaurantLocation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await ApiClient.postMultipart(
        ApiConfig.vendorRegister,
        {
          'owner_name': _ownerName.text.trim(),
          'owner_phone': _ownerPhone.text.trim(),
          'manager_email': _managerEmail.text.trim(),
          'manager_password': _managerPassword.text,
          'restaurant_name': _restaurantName.text.trim(),
          'restaurant_phone': _restaurantPhone.text.trim(),
          'restaurant_type': _restaurantType.text.trim(),
          'food_type': _foodType,
          'cuisine': _restaurantType.text.trim(),
          'description': _description.text.trim(),
          'address': _address.text.trim(),
          'lat': _lat,
          'lng': _lng,
          'fssai_number': _fssaiNumber.text.trim(),
          'tin_number': _tinNumber.text.trim(),
          if (_costForTwo.text.trim().isNotEmpty) 'cost_for_two': _costForTwo.text.trim(),
          'bank_account_number': _bankAccountNumber.text.trim(),
          'bank_ifsc': _bankIfsc.text.trim(),
          'bank_account_holder': _bankAccountHolder.text.trim(),
        },
        files: {
          if (_banner != null) 'restaurant_banner': _banner!,
          if (_logo != null) 'restaurant_logo': _logo!,
          if (_fssaiCertificate != null) 'fssai_certificate': _fssaiCertificate!,
          if (_tinCertificate != null) 'tin_certificate': _tinCertificate!,
        },
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.registeredExclaim),
          content: Text(res['message']?.toString() ?? AppLocalizations.of(context)!.vendorSuccessMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.openVendor)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionTitle('Restaurant & Owner'),
              TextFormField(
                controller: _restaurantName,
                decoration: InputDecoration(labelText: t.restaurantName),
                validator: (v) => (v == null || v.trim().length < 2) ? t.validatorRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerName,
                decoration: const InputDecoration(labelText: 'Owner Name'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Owner Mobile Number'),
                validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _managerEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.email),
                validator: (v) => (v == null || !v.contains('@')) ? t.validatorValidEmail : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _managerPassword,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password),
                validator: (v) => (v == null || v.length < 6) ? t.validatorMin6Chars : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _restaurantPhone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.restaurantPhone),
                validator: (v) => (v == null || v.trim().length < 10) ? t.validatorValidPhone : null,
              ),

              _sectionTitle('Location'),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: InputDecoration(labelText: t.addressField),
                validator: (v) => (v == null || v.trim().length < 5) ? t.enterCompleteAddress : null,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: Text(_lat == null ? t.pinRestaurantLocation : t.locationPinnedTapToChange),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Text(t.salemDistrictOnlyNote, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),

              _sectionTitle('Restaurant Details'),
              TextFormField(
                controller: _restaurantType,
                decoration: const InputDecoration(labelText: 'Restaurant Type (e.g. Restaurant, Cafe, Cloud Kitchen)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _foodType,
                decoration: const InputDecoration(labelText: 'Veg / Non-Veg'),
                items: const [
                  DropdownMenuItem(value: 'veg', child: Text('Veg only')),
                  DropdownMenuItem(value: 'non_veg', child: Text('Non-Veg only')),
                  DropdownMenuItem(value: 'both', child: Text('Veg & Non-Veg')),
                ],
                onChanged: (v) => setState(() => _foodType = v ?? 'both'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: InputDecoration(labelText: t.descriptionOptional),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costForTwo,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.approxCostForTwoOptional),
              ),
              const SizedBox(height: 8),
              FilePickerField(
                label: 'Restaurant Banner',
                helperText: 'Wide image for your restaurant card (ratio ~1.3)',
                onChanged: (f) => _banner = f,
                isImage: true,
              ),
              FilePickerField(
                label: 'Restaurant Logo',
                helperText: 'Square-ish logo (ratio ~1.1)',
                onChanged: (f) => _logo = f,
                isImage: true,
              ),

              _sectionTitle('Compliance'),
              TextFormField(
                controller: _fssaiNumber,
                decoration: const InputDecoration(labelText: 'FSSAI Certificate Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              FilePickerField(label: 'FSSAI Certificate', onChanged: (f) => _fssaiCertificate = f, isImage: false, required: true),
              TextFormField(
                controller: _tinNumber,
                decoration: const InputDecoration(labelText: 'TIN / GST Number (optional)'),
              ),
              FilePickerField(label: 'TIN Certificate', onChanged: (f) => _tinCertificate = f, isImage: false),

              _sectionTitle('Bank Details (optional)'),
              TextFormField(
                controller: _bankAccountNumber,
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankIfsc,
                decoration: const InputDecoration(labelText: 'IFSC Code'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccountHolder,
                decoration: const InputDecoration(labelText: 'Account Holder Name'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t.registerRestaurant),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
