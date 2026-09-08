class MenuItem {
  final int id;
  final int restaurantId;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final bool isVeg;
  final String? image;
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final String? restaurantName;
  final bool isOpen;
  final int likeCount;
  final bool likedByMe;

  MenuItem({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.isVeg = true,
    this.image,
    this.rating = 0,
    this.ratingCount = 0,
    this.isAvailable = true,
    this.restaurantName,
    this.isOpen = true,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: int.parse(j['id'].toString()),
        restaurantId: int.parse((j['restaurant_id'] ?? 0).toString()),
        categoryId: j['category_id'] != null ? int.tryParse(j['category_id'].toString()) : null,
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        price: double.tryParse(j['price']?.toString() ?? '') ?? 0,
        isVeg: j['is_veg'].toString() == '1' || j['is_veg'] == true,
        image: j['image']?.toString(),
        rating: double.tryParse(j['rating']?.toString() ?? '') ?? 0,
        ratingCount: int.tryParse(j['rating_count']?.toString() ?? '') ?? 0,
        isAvailable: j['is_available'] == null ? true : (j['is_available'].toString() == '1' || j['is_available'] == true),
        restaurantName: j['restaurant_name']?.toString(),
        isOpen: j['is_open'] == null ? true : (j['is_open'] == true || j['is_open'].toString() == '1'),
        likeCount: int.tryParse(j['like_count']?.toString() ?? '') ?? 0,
        likedByMe: j['liked_by_me'] == true || j['liked_by_me'].toString() == '1',
      );
}
