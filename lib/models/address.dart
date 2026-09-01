class Address {
  final int id;
  final String label;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: int.parse(j['id'].toString()),
        label: j['label']?.toString() ?? 'Address',
        addressLine: j['address_line']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        state: j['state']?.toString() ?? '',
        pincode: j['pincode']?.toString() ?? '',
        isDefault: j['is_default'].toString() == '1' || j['is_default'] == true,
      );

  String get full => '$addressLine, $city, $state - $pincode';
}
