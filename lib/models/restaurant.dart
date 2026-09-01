class Restaurant {
  final int id;
  final String name;
  final String? cuisine;
  final String? description;
  final String? image;
  final double rating;
  final int ratingCount;
  final String? phone;
  final int prepTimeMin;
  final int prepTimeMax;
  final int costForTwo;
  final String? discountLabel;
  final bool isOpen;
  final int likeCount;
  final bool likedByMe;

  Restaurant({
    required this.id,
    required this.name,
    this.cuisine,
    this.description,
    this.image,
    this.rating = 0,
    this.ratingCount = 0,
    this.phone,
    this.prepTimeMin = 20,
    this.prepTimeMax = 40,
    this.costForTwo = 0,
    this.discountLabel,
    this.isOpen = true,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        cuisine: j['cuisine']?.toString(),
        description: j['description']?.toString(),
        image: j['image']?.toString(),
        rating: double.tryParse(j['rating']?.toString() ?? '') ?? 0,
        ratingCount: int.tryParse(j['rating_count']?.toString() ?? '') ?? 0,
        phone: j['phone']?.toString(),
        prepTimeMin: int.tryParse(j['prep_time_min']?.toString() ?? '') ?? 20,
        prepTimeMax: int.tryParse(j['prep_time_max']?.toString() ?? '') ?? 40,
        costForTwo: int.tryParse(j['cost_for_two']?.toString() ?? '') ?? 0,
        discountLabel: (j['discount_label']?.toString().isEmpty ?? true) ? null : j['discount_label'].toString(),
        isOpen: j['is_open'] == true || j['is_open'].toString() == '1',
        likeCount: int.tryParse(j['like_count']?.toString() ?? '') ?? 0,
        likedByMe: j['liked_by_me'] == true || j['liked_by_me'].toString() == '1',
      );

  Restaurant copyWith({bool? likedByMe, int? likeCount}) => Restaurant(
        id: id,
        name: name,
        cuisine: cuisine,
        description: description,
        image: image,
        rating: rating,
        ratingCount: ratingCount,
        phone: phone,
        prepTimeMin: prepTimeMin,
        prepTimeMax: prepTimeMax,
        costForTwo: costForTwo,
        discountLabel: discountLabel,
        isOpen: isOpen,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}
