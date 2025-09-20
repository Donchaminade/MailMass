// import 'package:shared_preferences/shared_preferences.dart';

// class BrandingService {
//   static const String _logoPathKey = 'logo_path';
//   static const String _signatureKey = 'signature';

//   Future<void> saveLogoPath(String path) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_logoPathKey, path);
//   }

//   Future<String?> getLogoPath() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_logoPathKey);
//   }

//   Future<void> saveSignature(String signature) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_signatureKey, signature);
//   }

//   Future<String?> getSignature() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_signatureKey);
//   }
// }
