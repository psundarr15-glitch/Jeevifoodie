import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/chat/chats_list_screen.dart';

class RootShell extends StatefulWidget {
  final int initialIndex;
  const RootShell({super.key, this.initialIndex = 0});
  @override State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex;
  static const _tabs = [HomeScreen(), SearchScreen(), OrdersScreen(), ChatsListScreen(), CartScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<AppState>().cartCount;
    final t = AppLocalizations.of(context)!;
    final items = [
      (Icons.home_rounded, Icons.home_outlined, t.navHome),
      (Icons.search_rounded, Icons.search_rounded, t.navSearch),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, t.navOrders),
      (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, t.navChats),
      (Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, t.navCart),
      (Icons.person_rounded, Icons.person_outline_rounded, t.navProfile),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 20, offset: Offset(0, -5))]),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 78,
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = _index == i;
                final item = items[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(color: selected ? const Color(0xFFFFEEF1) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Stack(clipBehavior: Clip.none, children: [
                            Icon(selected ? item.$1 : item.$2, size: 23, color: selected ? const Color(0xFFF22549) : const Color(0xFF697386)),
                            if (i == 4 && cartCount > 0) Positioned(right: -8, top: -8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF22549), borderRadius: BorderRadius.circular(10)), child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))))
                          ]),
                          const SizedBox(height: 4),
                          Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? const Color(0xFFF22549) : const Color(0xFF697386))),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
