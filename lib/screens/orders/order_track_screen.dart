import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../models/order.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../chat/chat_screen.dart';

/// Order tracking screen with a live map (matches the website, which uses
/// Leaflet + OpenStreetMap - no API key needed, so we mirror that here
/// with flutter_map instead of requiring a Google Maps key).
class OrderTrackScreen extends StatefulWidget {
  final String orderCode;
  const OrderTrackScreen({super.key, required this.orderCode});

  @override
  State<OrderTrackScreen> createState() => _OrderTrackScreenState();
}

class _OrderTrackScreenState extends State<OrderTrackScreen> {
  late Future<OrderTrackingInfo> _future;
  Timer? _poll;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  static const _stages = ['placed', 'confirmed', 'preparing', 'picked_up', 'out_for_delivery', 'delivered'];

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 15s so status updates without the user manually refreshing.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  void _load() {
    final future = OrderService.track(widget.orderCode);
    setState(() => _future = future);
    future.then((info) {
      if (!mounted || !_mapReady) return;
      final lat = info.lat ?? info.restaurantLat;
      final lng = info.lng ?? info.restaurantLng;
      if (lat != null && lng != null) {
        _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.orderHash(widget.orderCode))),
      body: FutureBuilder<OrderTrackingInfo>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorLabel(snap.error.toString())));
          }
          final info = snap.data!;
          final currentIndex = _stages.indexOf(info.orderStatus);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (info.orderStatus == 'delivered' && !info.reviewed) ...[
                _RateOrderBanner(info: info, onRated: _load),
                const SizedBox(height: 16),
              ],
              if (info.etaMin != null)
                Card(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.estimatedDeliveryMin(info.etaMin.toString()), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (info.deliveryOtpRequired && info.deliveryOtp != null && info.deliveryOtp!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.lock_outline), const SizedBox(width: 8), Text('Delivery OTP', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 8),
                        Text(info.deliveryOtp!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Share this OTP with the delivery partner only when your order arrives.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (info.restaurantId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          restaurantId: info.restaurantId,
                          restaurantName: info.restaurantName,
                          orderId: info.orderId,
                          orderCode: widget.orderCode,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text('${AppLocalizations.of(context)!.chatWithRestaurant}${info.restaurantName != null ? ' — ${info.restaurantName}' : ''}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              _TrackingMap(
                mapController: _mapController,
                partnerLat: info.lat,
                partnerLng: info.lng,
                restaurantLat: info.restaurantLat,
                restaurantLng: info.restaurantLng,
                onReady: () {
                  _mapReady = true;
                },
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.statusLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (int i = 0; i < _stages.length; i++)
                _StageRow(
                  label: _label(_stages[i]),
                  done: currentIndex >= 0 && i <= currentIndex,
                  isLast: i == _stages.length - 1,
                ),
              if (info.partnerName != null) ...[
                const Divider(height: 32),
                Text(AppLocalizations.of(context)!.deliveryPartnerLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.delivery_dining)),
                  title: Text(info.partnerName!),
                  subtitle: info.partnerPhone != null ? Text(info.partnerPhone!) : null,
                ),
              ],
              if (info.items.isNotEmpty) ...[
                const Divider(height: 32),
                Text(AppLocalizations.of(context)!.itemsLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final item in info.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['item_name']} x${item['quantity']}'),
                        Text('₹${item['price']}'),
                      ],
                    ),
                  ),
              ],
              if (info.history.isNotEmpty) ...[
                const Divider(height: 32),
                Text(AppLocalizations.of(context)!.historyLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final h in info.history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline, size: 20),
                    title: Text(_label(h['status']?.toString() ?? '')),
                    subtitle: h['note'] != null ? Text(h['note'].toString()) : null,
                    trailing: h['created_at'] != null ? Text(h['created_at'].toString().split(' ').last) : null,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _label(String stage) {
    final t = AppLocalizations.of(context)!;
    switch (stage) {
      case 'placed':
        return t.stagePlaced;
      case 'confirmed':
        return t.stageConfirmed;
      case 'preparing':
        return t.stagePreparing;
      case 'picked_up':
        return 'Picked Up';
      case 'out_for_delivery':
        return t.stageOutForDelivery;
      case 'delivered':
        return t.stageDelivered;
      case 'cancelled':
        return t.stageCancelled;
      default:
        return stage;
    }
  }
}

class _TrackingMap extends StatelessWidget {
  final MapController mapController;
  final double? partnerLat;
  final double? partnerLng;
  final double? restaurantLat;
  final double? restaurantLng;
  final VoidCallback onReady;

  const _TrackingMap({
    required this.mapController,
    required this.partnerLat,
    required this.partnerLng,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    final hasPartner = partnerLat != null && partnerLng != null;
    final hasRestaurant = restaurantLat != null && restaurantLng != null;

    if (!hasPartner && !hasRestaurant) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Text(AppLocalizations.of(context)!.liveLocationWillAppear, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
      );
    }

    final center = hasPartner ? LatLng(partnerLat!, partnerLng!) : LatLng(restaurantLat!, restaurantLng!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            onMapReady: onReady,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.foodexpress.customer_app',
            ),
            MarkerLayer(
              markers: [
                if (hasRestaurant)
                  Marker(
                    point: LatLng(restaurantLat!, restaurantLng!),
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.storefront, color: AppTheme.primary, size: 32),
                  ),
                if (hasPartner)
                  Marker(
                    point: LatLng(partnerLat!, partnerLng!),
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.delivery_dining, color: Colors.red, size: 32),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool isLast;
  const _StageRow({required this.label, required this.done, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = done ? Colors.green : Colors.grey.shade400;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 22),
            if (!isLast) Container(width: 2, height: 28, color: color.withOpacity(0.4)),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(label, style: TextStyle(color: done ? Colors.black : Colors.grey, fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
        ),
      ],
    );
  }
}

/// Prompt shown on a delivered, not-yet-reviewed order. Tapping it opens
/// a bottom sheet to rate the restaurant (always) and the delivery
/// partner (only if one was assigned to this order).
class _RateOrderBanner extends StatelessWidget {
  final OrderTrackingInfo info;
  final VoidCallback onRated;
  const _RateOrderBanner({required this.info, required this.onRated});

  Future<void> _openSheet(BuildContext context) async {
    final rated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RateOrderSheet(info: info),
    );
    if (rated == true) onRated();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      color: AppTheme.primary.withOpacity(0.08),
      child: ListTile(
        leading: const Icon(Icons.star_outline, color: AppTheme.primary),
        title: Text(t.rateYourOrder, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(t.rateYourOrderSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openSheet(context),
      ),
    );
  }
}

class _RateOrderSheet extends StatefulWidget {
  final OrderTrackingInfo info;
  const _RateOrderSheet({required this.info});
  @override
  State<_RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends State<_RateOrderSheet> {
  int _restaurantRating = 0;
  int _partnerRating = 0;
  final _comment = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (_restaurantRating == 0) {
      setState(() => _error = t.pleaseRateRestaurant);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ReviewService.submit(
        orderId: widget.info.orderId,
        rating: _restaurantRating,
        partnerRating: widget.info.deliveryPartnerId != null && _partnerRating > 0 ? _partnerRating : null,
        comment: _comment.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(t.rateYourOrder, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(widget.info.restaurantName ?? t.restaurantLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _StarPicker(value: _restaurantRating, onChanged: (v) => setState(() => _restaurantRating = v)),
            if (widget.info.deliveryPartnerId != null) ...[
              const SizedBox(height: 20),
              Text(widget.info.partnerName ?? t.deliveryPartnerLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _StarPicker(value: _partnerRating, onChanged: (v) => setState(() => _partnerRating = v)),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: InputDecoration(hintText: t.addACommentOptional, border: const OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t.submitRating),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _StarPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(i + 1),
          icon: Icon(filled ? Icons.star : Icons.star_border, color: AppTheme.gold, size: 32),
        );
      }),
    );
  }
}
