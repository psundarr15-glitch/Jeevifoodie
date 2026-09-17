class CartItem {
  final int id; // cart_item_id
  final int menuItemId;
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;
  final String? image;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.isVeg = true,
    this.image,
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: int.parse(j['id'].toString()),
        menuItemId: int.parse((j['menu_item_id'] ?? 0).toString()),
        name: j['name']?.toString() ?? j['item_name']?.toString() ?? '',
        price: double.tryParse(j['price']?.toString() ?? '') ?? 0,
        quantity: int.tryParse(j['quantity']?.toString() ?? '') ?? 1,
        isVeg: j['is_veg'].toString() == '1' || j['is_veg'] == true,
        image: (j['image']?.toString().isEmpty ?? true) ? null : j['image'].toString(),
      );
}
