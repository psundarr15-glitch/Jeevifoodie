import 'package:flutter/material.dart';

class TrustBadgesRow extends StatelessWidget {
  const TrustBadgesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: const [
              Expanded(child: _Badge(icon: Icons.location_on_outlined, label: 'Live Tracking', sub: 'Track your order')),
              Expanded(child: _Badge(icon: Icons.verified_user_outlined, label: 'Secure Payment', sub: '100% Secure')),
              Expanded(child: _Badge(icon: Icons.autorenew, label: 'Easy Returns', sub: 'Hassle free')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _Badge({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
        Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }
}
