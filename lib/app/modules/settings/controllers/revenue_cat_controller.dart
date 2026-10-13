import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../res/colors/app_color.dart';
import '../../../../res/components/api_service.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/entitlement.dart';

class RevenueCatController extends GetxController {
  final _entitlement = Entitlement.free.obs;
  final _renewalDate = ''.obs;
  final _activeProductName = ''.obs;
  final _activeProductPriceString = ''.obs;

  String _lastSyncedDate = 'INITIAL';

  Entitlement get entitlement => _entitlement.value;
  String get renewalDate => _renewalDate.value;
  String get activeProductName => _activeProductName.value;
  String get activeProductPriceString => _activeProductPriceString.value;

  final storage = const FlutterSecureStorage();
  final apiService = ApiService();

  static const MethodChannel _subChannel = MethodChannel('com.tapqrlink/subscriptions');

  Future<void> manageSubscription() async {
    try {
      if (Platform.isIOS) {
        try {
          await _subChannel.invokeMethod('showManageSubscriptions');
          await updatePurchaseStatus();
          return;
        } catch (e) {
          debugPrint("MethodChannel showManageSubscriptions error: $e");
          final Uri appStoreUrl = Uri.parse("itms-apps://apps.apple.com/account/subscriptions");
          if (await canLaunchUrl(appStoreUrl)) {
            await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
            await updatePurchaseStatus();
            return;
          }
        }
      } else if (Platform.isAndroid) {
        final Uri playStoreUrl = Uri.parse(
          "https://play.google.com/store/account/subscriptions?package=com.tapqrlink.tapqrlink",
        );
        if (await canLaunchUrl(playStoreUrl)) {
          await launchUrl(playStoreUrl, mode: LaunchMode.externalNonBrowserApplication);
          await updatePurchaseStatus();
          return;
        }
      }
    } catch (e) {
      debugPrint("Error managing subscription: $e");
      showCustomSnackBar(
        title: 'Manage Subscription',
        message: 'Please open your App Store / Play Store account settings to manage subscriptions.',
        isSuccess: false,
      );
    }
  }

  Future<void> restorePurchases() async {
    try {
      if (!await Purchases.isConfigured) return;
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      await updatePurchaseStatus(info: customerInfo);
      if (entitlement == Entitlement.allFeatures) {
        showCustomSnackBar(
          title: 'Purchases Restored',
          message: 'Your active subscription has been successfully restored.',
          isSuccess: true,
        );
      } else {
        showCustomSnackBar(
          title: 'No Active Subscription',
          message: 'No active subscription was found to restore.',
          backgroundColor: AppColor.orangeColor,
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint("Restore purchases error: $e");
      showCustomSnackBar(
        title: 'Restore Failed',
        message: 'Could not restore purchases. Please try again.',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    while (!await Purchases.isConfigured) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      updatePurchaseStatus(info: customerInfo);
    });
    await updatePurchaseStatus();
  }

  Future<void> updatePurchaseStatus({CustomerInfo? info}) async {
    try {
      if (!await Purchases.isConfigured) return;
      CustomerInfo customerInfo = info ?? await Purchases.getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active;

      if (activeEntitlements.isEmpty) {
        _entitlement.value = Entitlement.free;
        _renewalDate.value = '';
        _activeProductName.value = '';
        _activeProductPriceString.value = '';
      } else {
        _entitlement.value = Entitlement.allFeatures;
        final entitlementInfo = activeEntitlements.values.first;

        if (entitlementInfo.expirationDate != null) {
          try {
            DateTime expiry = DateTime.parse(entitlementInfo.expirationDate!);
            _renewalDate.value = DateFormat('yyyy-MM-dd').format(expiry);
          } catch (e) {
            _renewalDate.value = entitlementInfo.expirationDate!.split('T')[0];
          }
        } else {
          _renewalDate.value = '';
        }

        // Fetch name and price from offerings dynamically
        String prodName = 'Premium Subscription';
        String prodPrice = '';
        try {
          final offerings = await Purchases.getOfferings();
          final current = offerings.current;
          if (current != null) {
            for (var package in current.availablePackages) {
              if (package.storeProduct.identifier == entitlementInfo.productIdentifier) {
                prodName = package.storeProduct.title;
                prodPrice = '${package.storeProduct.priceString} per ${package.packageType == PackageType.annual ? 'year' : package.packageType == PackageType.monthly ? 'month' : 'period'}';
                break;
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching product details for active entitlement: $e");
        }

        _activeProductName.value = prodName;
        _activeProductPriceString.value = prodPrice;
      }

      if (_lastSyncedDate != _renewalDate.value) {
        await syncSubscriptionWithBackend();
      }
    } catch (e) {
      debugPrint("Error updating purchase status: $e");
    }
  }

  Future<void> syncSubscriptionWithBackend({bool force = false}) async {
    try {
      if (!force && _lastSyncedDate == _renewalDate.value) {
        debugPrint("RevenueCatController: Sync skipped as date has not changed: ${_renewalDate.value}");
        return;
      }

      String? token = await storage.read(key: 'access');
      if (token == null) {
        debugPrint("RevenueCatController: Access token is null, skipping backend sync.");
        return;
      }

      debugPrint("RevenueCatController: Syncing subscription date to backend: ${_renewalDate.value} (force: $force)");
      var response = await apiService.updateSubscriptionDate(
        token,
        _renewalDate.value,
      );

      final isTokenExpired = response['statusCode'] == 401 ||
          (response['data'] is Map &&
              (response['data']['code'] == 'token_not_valid' ||
                  response['data']['detail'] == 'Given token not valid for any token type'));

      if (isTokenExpired) {
        debugPrint("RevenueCatController: Access token expired. Attempting refresh...");
        final refreshToken = await storage.read(key: 'refresh');
        if (refreshToken != null && refreshToken.isNotEmpty) {
          if (Get.isRegistered<AuthController>()) {
            final authController = Get.find<AuthController>();
            final refreshed = await authController.refreshAccessToken(refreshToken);
            if (refreshed) {
              token = await storage.read(key: 'access');
              if (token != null) {
                response = await apiService.updateSubscriptionDate(
                  token,
                  _renewalDate.value,
                );
              }
            } else {
              debugPrint("RevenueCatController: Refresh token also expired.");
            }
          }
        }
      }

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        _lastSyncedDate = _renewalDate.value;
        debugPrint("Backend Sub Date Synced: ${_renewalDate.value}");
      } else {
        debugPrint("Backend Sub Date Sync failed: ${response['data']}");
      }
    } catch (e) {
      debugPrint("Failed to sync sub date to Django: $e");
    }
  }

  Future<void> clearData() async {
    try {
      if (await Purchases.isConfigured) {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();

        if (!customerInfo.originalAppUserId.startsWith("\$RCAnonymousID")) {
          await Purchases.logOut();
          debugPrint('RevenueCat: Identified user logged out.');
        } else {
          debugPrint('RevenueCat: Current user is anonymous, skipping logOut.');
        }
      }

      _entitlement.value = Entitlement.free;
      _renewalDate.value = '';
      _lastSyncedDate = 'INITIAL';
    } catch (e) {
      debugPrint("Error clearing RevenueCat data: $e");
    }
  }
}
