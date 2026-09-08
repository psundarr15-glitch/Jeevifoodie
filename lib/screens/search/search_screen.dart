import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/search_service.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import 'search_results_screen.dart';
import 'item_detail_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<String> _recent = [];
  List<Category> _categories = [];
  List<MenuItem> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recent = await SearchService.recentSearches();
    try {
      final home = await CustomerService.home();
      if (mounted) {
        setState(() {
          _recent = recent;
          _categories = home.categories;
          _suggestions = home.popularItems.take(6).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _recent = recent; _loading = false; });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await SearchService.addRecentSearch(trimmed);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchResultsScreen(initialQuery: trimmed)));
    _load();
  }

  Future<void> _clearAllRecent() async {
    await SearchService.clearRecentSearches();
    setState(() => _recent = []);
  }

  Future<void> _removeRecent(String query) async {
    await SearchService.removeRecentSearch(query);
    setState(() => _recent.remove(query));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_recent.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.yourLastSearch, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: _clearAllRecent,
                            child: Text(t.clearAll, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final q in _recent)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.search, color: Colors.grey),
                          title: Text(q),
                          trailing: GestureDetector(
                            onTap: () => _removeRecent(q),
                            child: const Icon(Icons.close, size: 20, color: Colors.grey),
                          ),
                          onTap: () => _runSearch(q),
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (_suggestions.isNotEmpty) ...[
                      Text(t.suggestions, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.6,
                        ),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, i) {
                          final item = _suggestions[i];
                          return _SuggestionTile(
                            item: item,
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (_) => ItemDetailSheet(item: item),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_categories.isNotEmpty) ...[
                      Text(t.popularCategories, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((c) {
                          return GestureDetector(
                            onTap: () => _runSearch(c.displayName(context)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)),
                              child: Text(c.displayName(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const _SuggestionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&h=200&fit=crop';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.image?.isNotEmpty == true ? item.image! : fallbackImage,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(fallbackImage, width: 48, height: 48, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
