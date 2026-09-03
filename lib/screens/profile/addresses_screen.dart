import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../models/address.dart';
import '../../theme.dart';
import '../checkout/add_address_screen.dart';
import '../../l10n/app_localizations.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<List<Address>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ProfileService.view().then((d) => d.addresses);
  }

  Future<void> _setDefault(Address a) async {
    await ProfileService.setDefaultAddress(a.id);
    setState(_load);
  }

  Future<void> _delete(Address a) async {
    await ProfileService.deleteAddress(a.id);
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.addresses),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
              setState(_load);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Address>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(t.errorLabel(snap.error.toString())));
          }
          final addresses = snap.data!;
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_work_outlined, size: 96, color: AppTheme.primary.withOpacity(0.35)),
                    const SizedBox(height: 24),
                    Text(t.noSavedAddressFoundTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      t.noSavedAddressFoundSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
                        setState(_load);
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text(t.addAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final a = addresses[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(a.label),
                  subtitle: Text(a.full),
                  leading: Icon(a.isDefault ? Icons.star : Icons.star_border, color: Colors.amber),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'default' ? _setDefault(a) : _delete(a),
                    itemBuilder: (_) => [
                      if (!a.isDefault) PopupMenuItem(value: 'default', child: Text(t.setAsDefault)),
                      PopupMenuItem(value: 'delete', child: Text(t.delete)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
