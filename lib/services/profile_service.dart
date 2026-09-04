import '../config/api_config.dart';
import '../models/address.dart';
import 'api_client.dart';

class ProfileData {
  final Map<String, dynamic> user;
  final List<Address> addresses;
  ProfileData({required this.user, required this.addresses});
}

class ProfileService {
  static Future<ProfileData> view() async {
    final res = await ApiClient.get(ApiConfig.profileView);
    return ProfileData(
      user: res['user'] as Map<String, dynamic>,
      addresses: (res['addresses'] as List? ?? [])
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<void> update({required String name, String? phone}) async {
    await ApiClient.post(ApiConfig.profileUpdate, {
      'name': name,
      // Only sent when actually changing it - re-sending the same
      // phone back unnecessarily re-triggers the backend's phone
      // uniqueness check against this same record.
      if (phone != null) 'phone': phone,
    });
  }

  static Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await ApiClient.post(ApiConfig.changePassword, {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  static Future<void> deleteAccount({required String password}) async {
    await ApiClient.post(ApiConfig.deleteAccount, {'password': password});
  }

  static Future<Address> addAddress({
    required String label,
    String? contactName,
    String? contactPhone,
    required String addressLine,
    String? streetNumber,
    String? house,
    String? floor,
    required String city,
    required String state,
    required String pincode,
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    final res = await ApiClient.post(ApiConfig.addAddress, {
      'label': label,
      if (contactName != null && contactName.isNotEmpty) 'contact_name': contactName,
      if (contactPhone != null && contactPhone.isNotEmpty) 'contact_phone': contactPhone,
      'address_line': addressLine,
      if (streetNumber != null && streetNumber.isNotEmpty) 'street_number': streetNumber,
      if (house != null && house.isNotEmpty) 'house': house,
      if (floor != null && floor.isNotEmpty) 'floor': floor,
      'city': city,
      'state': state,
      'pincode': pincode,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'is_default': isDefault ? 1 : 0,
    });
    return Address.fromJson(res['address'] as Map<String, dynamic>);
  }

  static Future<void> setDefaultAddress(int id) async {
    await ApiClient.post(ApiConfig.setDefaultAddress(id));
  }

  static Future<void> deleteAddress(int id) async {
    await ApiClient.post(ApiConfig.deleteAddress(id));
  }

  static Future<(double, List<Map<String, dynamic>>)> wallet() async {
    final res = await ApiClient.get(ApiConfig.wallet);
    final balance = double.tryParse(res['balance']?.toString() ?? '') ?? 0;
    final transactions = (res['transactions'] as List? ?? []).cast<Map<String, dynamic>>();
    return (balance, transactions);
  }
}
