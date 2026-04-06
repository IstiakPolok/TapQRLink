import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../res/components/api_service.dart';
import '../models/entitlement.dart';

class RevenueCatController extends GetxController {
  final _entitlement = Entitlement.free.obs;
  final _renewalDate = ''.obs;

  String _lastSyncedDate = 'INITIAL';

  Entitlement get entitlement => _entitlement.value;
  String get renewalDate => _renewalDate.value;

  final storage = const FlutterSecureStorage();
  final apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      updatePurchaseStatus(info: customerInfo);
    });
    await updatePurchaseStatus();
  }

  Future<void> updatePurchaseStatus({CustomerInfo? info}) async {
    try {
      CustomerInfo customerInfo = info ?? await Purchases.getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active;

      if (activeEntitlements.isEmpty) {
        _entitlement.value = Entitlement.free;
        _renewalDate.value = '';
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
        }
      }

      if (_lastSyncedDate != _renewalDate.value) {
        await syncSubscriptionWithBackend();
      }
    } catch (e) {
      debugPrint("Error updating purchase status: $e");
    }
  }

  Future<void> syncSubscriptionWithBackend() async {
    try {
      final token = await storage.read(key: 'access');
      if (token == null) return;

      final response = await apiService.updateSubscriptionDate(
        token,
        _renewalDate.value,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        _lastSyncedDate = _renewalDate.value;
        debugPrint("Backend Sub Date Synced: ${_renewalDate.value}");
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
