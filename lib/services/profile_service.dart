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

  static Future<void> update({required String name, required String phone}) async {
    await ApiClient.post(ApiConfig.profileUpdate, {'name': name, 'phone': phone});
  }

  static Future<Address> addAddress({
    required String label,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    final res = await ApiClient.post(ApiConfig.addAddress, {
      'label': label,
      'address_line': addressLine,
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
