import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/file_picker_field.dart';
import '../checkout/location_picker_screen.dart';

class DeliveryPartnerSignupScreen extends StatefulWidget {
  const DeliveryPartnerSignupScreen({super.key});
  @override
  State<DeliveryPartnerSignupScreen> createState() => _DeliveryPartnerSignupScreenState();
}

class _DeliveryPartnerSignupScreenState extends State<DeliveryPartnerSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _dob;

  final _city = TextEditingController();
  final _district = TextEditingController();
  final _pincode = TextEditingController();
  double? _lat;
  double? _lng;

  final _aadhaar = TextEditingController();
  final _licenseNumber = TextEditingController();
  String _vehicleType = 'bike';
  final _vehicleNumber = TextEditingController();
  final _rcNumber = TextEditingController();

  final _bankAccountNumber = TextEditingController();
  final _bankIfsc = TextEditingController();
  final _bankAccountHolder = TextEditingController();

  File? _photo;
  File? _idProof;
  File? _rcDocument;

  bool _saving = false;
  String? _error;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 70),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickAddressLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (picked == null) return;
    setState(() {
      _lat = picked.lat;
      _lng = picked.lng;
      if (_city.text.trim().isEmpty && picked.city.isNotEmpty) _city.text = picked.city;
      if (_pincode.text.trim().isEmpty && picked.pincode.isNotEmpty) _pincode.text = picked.pincode;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dobStr =
          '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';
      final res = await ApiClient.postMultipart(
        ApiConfig.deliveryPartnerRegister,
        {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'phone': _phone.text.trim(),
          'dob': dobStr,
          'city': _city.text.trim(),
          'district': _district.text.trim(),
          'pincode': _pincode.text.trim(),
          if (_lat != null) 'lat': _lat,
          if (_lng != null) 'lng': _lng,
          'aadhaar_number': _aadhaar.text.trim(),
          'license_number': _licenseNumber.text.trim(),
          'vehicle_type': _vehicleType,
          'vehicle_number': _vehicleNumber.text.trim(),
          'rc_number': _rcNumber.text.trim(),
          'bank_account_number': _bankAccountNumber.text.trim(),
          'bank_ifsc': _bankIfsc.text.trim(),
          'bank_account_holder': _bankAccountHolder.text.trim(),
        },
        files: {
          if (_photo != null) 'photo': _photo!,
          if (_idProof != null) 'id_proof_document': _idProof!,
          if (_rcDocument != null) 'rc_document': _rcDocument!,
        },
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.registeredExclaim),
          content: Text(res['message']?.toString() ?? AppLocalizations.of(context)!.deliveryPartnerSuccessMessage),
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
      appBar: AppBar(title: Text(t.joinAsDeliveryMan)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionTitle('Personal Details'),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: t.fullNameField),
                validator: (v) => (v == null || v.trim().length < 2) ? t.validatorRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.phone),
                validator: (v) => (v == null || v.trim().length < 10) ? t.validatorValidPhone : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.email),
                validator: (v) => (v == null || !v.contains('@')) ? t.validatorValidEmail : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password),
                validator: (v) => (v == null || v.length < 6) ? t.validatorMin6Chars : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  child: Text(_dob == null ? 'Tap to select' : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
                ),
              ),
              const SizedBox(height: 16),
              FilePickerField(label: 'Profile Photo', onChanged: (f) => _photo = f, isImage: true),

              _sectionTitle('Address'),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City / Town'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _district,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Pincode'),
                validator: (v) => (v == null || !RegExp(r'^[0-9]{6}$').hasMatch(v.trim())) ? 'Enter a valid 6-digit pincode' : null,
              ),
              OutlinedButton.icon(
                onPressed: _pickAddressLocation,
                icon: const Icon(Icons.map_outlined),
                label: Text(_lat == null ? 'Pin address on map' : 'Location pinned - tap to change'),
              ),

              _sectionTitle('Identity & Vehicle'),
              TextFormField(
                controller: _aadhaar,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: const InputDecoration(labelText: 'Aadhaar Number'),
                validator: (v) => (v == null || !RegExp(r'^[0-9]{12}$').hasMatch(v.trim())) ? 'Enter a valid 12-digit Aadhaar number' : null,
              ),
              FilePickerField(label: 'Aadhaar / ID Proof document', onChanged: (f) => _idProof = f, isImage: false, required: true),
              TextFormField(
                controller: _licenseNumber,
                decoration: const InputDecoration(labelText: 'Driving Licence Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                items: const [
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                  DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                  DropdownMenuItem(value: 'car', child: Text('Car')),
                ],
                onChanged: (v) => setState(() => _vehicleType = v ?? 'bike'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicleNumber,
                decoration: InputDecoration(labelText: t.vehicleNumber),
                validator: (v) => (v == null || v.trim().isEmpty) ? t.validatorRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rcNumber,
                decoration: const InputDecoration(labelText: 'RC Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              FilePickerField(label: 'RC Document', onChanged: (f) => _rcDocument = f, isImage: false, required: true),

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
                    : Text(t.register),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
