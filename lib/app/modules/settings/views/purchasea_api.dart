// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseApi {
  static const _apiKey = 'goog_IzfnIIlGDwAuEaSXJVnqWKAzaoq';

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(_apiKey);
    await Purchases.configure(configuration);
  }

  static Future<List<Offering>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      return current == null ? <Offering>[] : <Offering>[current];
    } on PlatformException catch (e) {
      debugPrint('Error fetching offers: $e');
      return <Offering>[];
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } catch (e) {
      return false;
    }
  }
}
