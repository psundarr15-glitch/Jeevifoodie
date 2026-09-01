import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String? nameTa;
  final String? icon;

  Category({required this.id, required this.name, this.nameTa, this.icon});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        nameTa: (j['name_ta']?.toString().isEmpty ?? true) ? null : j['name_ta'].toString(),
        icon: (j['icon']?.toString().isEmpty ?? true) ? null : j['icon'].toString(),
      );

  /// Tamil name if the admin set one and the app is in Tamil, otherwise
  /// falls back to the English name - so a category with no Tamil name
  /// yet doesn't show up blank.
  String displayName(BuildContext context) {
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';
    if (isTamil && nameTa != null) return nameTa!;
    return name;
  }
}
