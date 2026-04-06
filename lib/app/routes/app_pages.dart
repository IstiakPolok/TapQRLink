import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/nav_bar.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/splash.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.onboarding;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => Navbar(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.auth,
      page: () => AuthView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.onboarding,
      page: () => SplashView(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.settings,
      page: () => SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}
