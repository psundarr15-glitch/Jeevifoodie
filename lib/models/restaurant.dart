class Restaurant {
  final int id;
  final String name;
  final String? cuisine;
  final String? description;
  final String? image;
  final String? logo;
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
  final double? distanceKm;
  final String? address;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    this.cuisine,
    this.description,
    this.image,
    this.logo,
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
    this.distanceKm,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        cuisine: j['cuisine']?.toString(),
        description: j['description']?.toString(),
        image: j['image']?.toString(),
        logo: j['logo']?.toString() ?? j['logo_url']?.toString(),
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
        distanceKm: j['distance_km'] != null ? double.tryParse(j['distance_km'].toString()) : null,
        address: j['address']?.toString() ?? j['location']?.toString(),
        latitude: double.tryParse((j['lat'] ?? j['latitude'] ?? '').toString()),
        longitude: double.tryParse((j['lng'] ?? j['longitude'] ?? '').toString()),
      );

  Restaurant copyWith({bool? likedByMe, int? likeCount}) => Restaurant(
        id: id,
        name: name,
        cuisine: cuisine,
        description: description,
        image: image,
        logo: logo,
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
        distanceKm: distanceKm,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
}
