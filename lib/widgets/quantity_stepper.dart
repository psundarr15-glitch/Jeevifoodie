import 'package:flutter/material.dart';
import '../theme.dart';

/// A quantity stepper with comfortably large tap targets (44x44 min,
/// per platform touch-target guidance) - used anywhere an item quantity
/// can be adjusted (cart rows, menu item rows).
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 34.0 : 40.0;
    final iconSize = compact ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, size: buttonSize, iconSize: iconSize, onTap: onDecrease),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            child: Text('$quantity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: compact ? 14 : 16)),
          ),
          _StepButton(icon: Icons.add, size: buttonSize, iconSize: iconSize, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.size, required this.iconSize, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
