class Address {
  final int id;
  final String label;
  final String? contactName;
  final String? contactPhone;
  final String addressLine;
  final String? streetNumber;
  final String? house;
  final String? floor;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    this.contactName,
    this.contactPhone,
    required this.addressLine,
    this.streetNumber,
    this.house,
    this.floor,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: int.parse(j['id'].toString()),
        label: j['label']?.toString() ?? 'Address',
        contactName: j['contact_name']?.toString(),
        contactPhone: j['contact_phone']?.toString(),
        addressLine: j['address_line']?.toString() ?? '',
        streetNumber: j['street_number']?.toString(),
        house: j['house']?.toString(),
        floor: j['floor']?.toString(),
        city: j['city']?.toString() ?? '',
        state: j['state']?.toString() ?? '',
        pincode: j['pincode']?.toString() ?? '',
        isDefault: j['is_default'].toString() == '1' || j['is_default'] == true,
      );

  String get full => '$addressLine, $city, $state - $pincode';
}
