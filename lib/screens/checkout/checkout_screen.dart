import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../services/checkout_service.dart';
import '../../models/address.dart';
import '../../state/app_state.dart';
import '../orders/order_placed_screen.dart';
import 'add_address_screen.dart';
import '../../l10n/app_localizations.dart';

class CheckoutScreen extends StatefulWidget {
  final double subtotal;
  const CheckoutScreen({super.key, required this.subtotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Address> _addresses = [];
  int? _selectedAddressId;
  String _paymentMethod = 'cod';
  bool _loadingAddresses = true;

  final _couponController = TextEditingController();
  double _discount = 0;
  int? _couponId;
  bool _applyingCoupon = false;
  String? _couponError;

  bool _placing = false;
  String? _placeError;
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    ProfileService.wallet().then((r) {
      if (mounted) setState(() => _walletBalance = r.$1);
    }).catchError((_) {});
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final data = await ProfileService.view();
      setState(() {
        _addresses = data.addresses;
        _selectedAddressId ??= data.addresses.isNotEmpty
            ? (data.addresses.firstWhere((a) => a.isDefault, orElse: () => data.addresses.first)).id
            : null;
        _loadingAddresses = false;
      });
    } catch (e) {
      setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) return;
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    try {
      final result = await CheckoutService.applyCoupon(
        code: _couponController.text.trim(),
        subtotal: widget.subtotal,
      );
      setState(() {
        _discount = result.discount;
        _couponId = result.couponId;
      });
    } catch (e) {
      setState(() {
        _couponError = e.toString();
        _discount = 0;
        _couponId = null;
      });
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  double get _deliveryFee => widget.subtotal >= 199 ? 0 : 30;
  double get _total {
    final t = widget.subtotal - _discount + _deliveryFee;
    return t < 0 ? 0 : t;
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      setState(() => _placeError = AppLocalizations.of(context)!.pleaseSelectDeliveryAddress);
      return;
    }
    setState(() {
      _placing = true;
      _placeError = null;
    });
    try {
      final order = await CheckoutService.placeOrder(
        addressId: _selectedAddressId!,
        paymentMethod: _paymentMethod,
        discount: _discount,
        couponId: _couponId,
      );
      if (!mounted) return;
      context.read<AppState>().refreshCartCount();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderPlacedScreen(orderCode: order['order_code'].toString())),
      );
    } catch (e) {
      setState(() => _placeError = e.toString());
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.checkout)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.deliveryAddress, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingAddresses)
            const Center(child: CircularProgressIndicator())
          else ...[
            for (final a in _addresses)
              RadioListTile<int>(
                value: a.id,
                groupValue: _selectedAddressId,
                onChanged: (v) => setState(() => _selectedAddressId = v),
                title: Text(a.label),
                subtitle: Text(a.full),
              ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                );
                _loadAddresses();
              },
              icon: const Icon(Icons.add),
              label: Text(t.addNewAddress),
            ),
          ],
          const Divider(height: 32),
          Text(t.couponLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(hintText: t.enterCouponCode),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyingCoupon ? null : _applyCoupon,
                child: _applyingCoupon
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t.apply),
              ),
            ],
          ),
          if (_couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_couponError!, style: const TextStyle(color: Colors.red)),
            ),
          const Divider(height: 32),
          Text(t.paymentMethod, style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<String>(
            value: 'cod',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            title: Text(t.cashOnDelivery),
          ),
          RadioListTile<String>(
            value: 'online',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            title: Text(t.onlinePayment),
          ),
          RadioListTile<String>(
            value: 'wallet',
            groupValue: _paymentMethod,
            onChanged: _walletBalance >= _total ? (v) => setState(() => _paymentMethod = v!) : null,
            title: Text(t.walletLabel),
            subtitle: Text(
              _walletBalance >= _total ? t.balanceAmount(_walletBalance.toStringAsFixed(2)) : t.insufficientBalance(_walletBalance.toStringAsFixed(2)),
            ),
          ),
          const Divider(height: 32),
          _summaryRow(t.subtotal, widget.subtotal),
          if (_discount > 0) _summaryRow(t.discount, -_discount),
          _summaryRow(t.deliveryFeeShort, _deliveryFee),
          const Divider(),
          _summaryRow(t.total, _total, bold: true),
          const SizedBox(height: 16),
          if (_placeError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_placeError!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: _placing ? null : _placeOrder,
            child: _placing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(t.placeOrder),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
