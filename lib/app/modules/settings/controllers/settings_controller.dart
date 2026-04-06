// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../res/components/api_service.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';

class PreferencesService {
  static Future setDarkMode(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    debugPrint('Saved isDarkMode: $value');
  }

  static Future<bool?> getDarkMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('isDarkMode');
    debugPrint('Loaded isDarkMode: $value');
    return value;
  }
}

class SettingsController extends GetxController {
  final ApiService apiService = ApiService();
  final AuthController authController = Get.find();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initPlatformState();
    loadPreferences();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      final systemDarkMode =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      PreferencesService.getDarkMode().then((savedValue) {
        if (savedValue == null) {
          isDarkMode.value = systemDarkMode;
          debugPrint(
            'System theme changed, no saved preference, isDarkMode: ${isDarkMode.value}',
          );
        }
      });
    };
  }

  Future loadPreferences() async {
    final savedDarkMode = await PreferencesService.getDarkMode();
    isDarkMode.value =
        savedDarkMode ??
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    debugPrint(
      'SettingsController initialized with isDarkMode: ${isDarkMode.value}, System Brightness: ${WidgetsBinding.instance.window.platformBrightness}',
    );
  }

  Future toggleDarkMode(bool value) async {
    isDarkMode.value = value;
    await PreferencesService.setDarkMode(isDarkMode.value);
    debugPrint('Toggled isDarkMode to: ${isDarkMode.value}');
  }

  var selectedPlanIndex = (-1).obs;

  var isLoading = false.obs;

  Future<void> deleteAccount() async {
    isLoading.value = true;
    await Future.delayed(Duration(seconds: 1));
    Get.toNamed(Routes.auth);
    isLoading.value = false;
  }

  void goToTermsAndConditions() {
    Get.toNamed('/terms');
  }

  final count = 0.obs;

  var isPremium = false.obs;
  var offerings = Rxn<Offerings>();

  Future<void> _initPlatformState() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (GetPlatform.isAndroid) {
      configuration = PurchasesConfiguration(
        "goog_IzfnIIlGDwAuEaSXJVnqWKAzaoq",
      );
    } else {
      configuration = PurchasesConfiguration("appl_your_public_api_key");
    }

    await Purchases.configure(configuration);

    refreshCustomerInfo();
    fetchOfferings();
  }

  Future<void> fetchOfferings() async {
    try {
      offerings.value = await Purchases.getOfferings();
    } catch (e) {
      Get.snackbar("Error", "Could not fetch offerings");
    }
  }

  Future<void> refreshCustomerInfo() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      isPremium.value =
          customerInfo.entitlements.all["premium"]?.isActive ?? false;
    } catch (e) {
      debugPrint("Error refreshing customer info: $e");
    }
  }

  Future<void> purchasePackage(Package package) async {
    try {
      PurchaseResult result = await Purchases.purchasePackage(package);
      if (result.customerInfo.entitlements.all["premium"]?.isActive == true) {
        isPremium.value = true;
        Navigator.pop(Get.context!);
        Get.snackbar("Success", "Welcome to Premium!");
      }
    } catch (e) {
      debugPrint('Error purchasing package: $e');
    }
  }
}
