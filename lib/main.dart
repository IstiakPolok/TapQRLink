import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/modules/auth/bindings/auth_binding.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/auth/controllers/notification_controller.dart';
import 'app/modules/home/controllers/home_controller.dart';
import 'app/modules/onboarding/controllers/onboarding_controller.dart';
import 'app/modules/settings/controllers/bottom_sheet_controller.dart';
import 'app/modules/settings/controllers/profile_controller.dart';
import 'app/modules/settings/controllers/revenue_cat_controller.dart';
import 'app/modules/settings/controllers/settings_controller.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';
import 'res/colors/app_color.dart';
import 'res/components/api_service.dart';
import 'res/components/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('📩 Background message received: ${message.data}');
  } catch (e, stackTrace) {
    debugPrint('❌ Error in background message handler: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp();

  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Get.put(OnboardingController());
  Get.put(ApiService());
  debugPrint(
    'ApiService registered at ${DateTime.now()}: ${Get.isRegistered()}',
  );

  Get.put(RevenueCatController());
  Get.put(ApiService());
  Get.put(NotificationService());
  Get.put(AuthController());
  Get.put(HomeController());
  final settingsController = Get.put(SettingsController());
  Get.put(ProfileController());
  Get.put(BottomSheetController());
  Get.put(NotificationController());

  await Get.find<NotificationService>().initialize();
  await settingsController.loadPreferences();
  debugPrint(
    'Main: Initial isDarkMode: ${settingsController.isDarkMode.value}',
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final isDeviceDarkMode =
            MediaQuery.of(context).platformBrightness == Brightness.dark;
        settingsController.isDarkMode.value = isDeviceDarkMode;
        return Obx(
          () => GetMaterialApp(
            initialBinding: AuthBinding(),
            debugShowCheckedModeBanner: false,
            title: "QR Code App",
            initialRoute: AppPages.initial,
            getPages: AppPages.routes,
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: AppColor.backgroundColor,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                backgroundColor: AppColor.backgroundColor,
                foregroundColor: Colors.black,
                scrolledUnderElevation: 0,
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.black),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: AppColor.darkThemeColor,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                backgroundColor: AppColor.darkThemeColor,
                foregroundColor: Colors.white,
                scrolledUnderElevation: 0,
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
              ),
            ),
            themeMode: settingsController.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
          ),
        );
      },
    ),
  );
}
