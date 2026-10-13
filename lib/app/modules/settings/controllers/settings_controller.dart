// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../res/components/api_service.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import 'revenue_cat_controller.dart';

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
    await authController.deleteAccount();
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
      configuration = PurchasesConfiguration("appl_ODWbbfJqDQsHWuikvFYKtXifiin");
    }

    await Purchases.configure(configuration);

    refreshCustomerInfo();
    fetchOfferings();
  }

  Future<void> fetchOfferings() async {
    try {
      offerings.value = await Purchases.getOfferings();
    } catch (e) {
      debugPrint("Error fetching offerings: $e");
    }
  }

  Future<void> refreshCustomerInfo() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      isPremium.value = customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint("Error refreshing customer info: $e");
    }
  }

  Future<void> purchasePackage(Package package) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      PurchaseResult result = await Purchases.purchasePackage(package);
      
      // Dismiss loading indicator
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      final hasActiveEntitlement = result.customerInfo.entitlements.active.isNotEmpty;
      if (hasActiveEntitlement) {
        isPremium.value = true;
        
        // Refresh RevenueCatController status
        final revenueCatController = Get.find<RevenueCatController>();
        await revenueCatController.updatePurchaseStatus(info: result.customerInfo);
        
        // Explicitly sync subscription date with backend after purchase
        await revenueCatController.syncSubscriptionWithBackend(force: true);
        
        // Close UpgradeView to return to SubscriptionView / SettingsView
        if (Navigator.canPop(Get.context!)) {
          Get.back();
        }

        showCustomSnackBar(
          title: "Success",
          message: "Welcome to Premium! You have full access.",
          isSuccess: true,
        );
      } else {
        showCustomSnackBar(
          title: "Error",
          message: "Purchase completed, but premium entitlement is not active.",
          isSuccess: false,
        );
      }
    } catch (e) {
      // Dismiss loading indicator if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      debugPrint('Error purchasing package: $e');
      final errStr = e.toString();
      if (!errStr.contains('PURCHASE_CANCELLED') && !errStr.contains('Purchase was cancelled')) {
        showCustomSnackBar(
          title: "Error",
          message: "Failed to complete purchase: $e",
          isSuccess: false,
        );
      }
    }
  }

  Future<void> restorePurchases() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      CustomerInfo customerInfo = await Purchases.restorePurchases();
      
      // Dismiss loading indicator
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      final hasActiveEntitlement = customerInfo.entitlements.active.isNotEmpty;
      if (hasActiveEntitlement) {
        isPremium.value = true;
        
        // Refresh RevenueCatController status
        final revenueCatController = Get.find<RevenueCatController>();
        await revenueCatController.updatePurchaseStatus(info: customerInfo);
        
        // Explicitly sync subscription date with backend
        await revenueCatController.syncSubscriptionWithBackend(force: true);
        
        if (Navigator.canPop(Get.context!)) {
          Get.back();
        }

        showCustomSnackBar(
          title: "Success",
          message: "Subscription successfully restored!",
          isSuccess: true,
        );
      } else {
        showCustomSnackBar(
          title: "Restore Purchases",
          message: "No active premium subscription found to restore.",
          isSuccess: false,
        );
      }
    } catch (e) {
      // Dismiss loading indicator if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      debugPrint('Error restoring purchases: $e');
      showCustomSnackBar(
        title: "Error",
        message: "Failed to restore purchases: $e",
        isSuccess: false,
      );
    }
  }
}
