import 'package:flutter/material.dart';
import '../services/notification_history_service.dart';
import '../screens/home/notifications_screen.dart';

/// The bell icon shown on the home app bar. Checks once on build whether
/// there's a broadcast newer than the last one the person actually
/// opened the list to see, and if so swings side-to-side a few times to
/// draw the eye - then stops, since a bell that never stops moving is
/// just annoying. Opening the notifications list marks everything as
/// seen, so the swing won't repeat until a genuinely new one arrives.
class NotificationBell extends StatefulWidget {
  final Color color;
  const NotificationBell({super.key, this.color = Colors.white});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _swing;
  bool _unread = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _swing = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.35), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.35, end: 0.28), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.28, end: -0.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(_controller);
    _checkUnread();
  }

  Future<void> _checkUnread() async {
    final unread = await NotificationHistoryService.hasUnread();
    if (!mounted) return;
    setState(() => _unread = unread);
    if (unread) _controller.repeat(period: const Duration(seconds: 2));
  }

  Future<void> _open() async {
    _controller.stop();
    setState(() => _unread = false);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _checkUnread(); // in case something new arrived while the list was open
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _swing,
            builder: (context, child) => Transform.rotate(angle: _swing.value * 0.5, child: child),
            child: Icon(Icons.notifications_none, color: widget.color, size: 28),
          ),
          if (_unread)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
