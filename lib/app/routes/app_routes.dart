part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const home = _Paths.home;
  static const auth = _Paths.auth;
  static const onboarding = _Paths.onboarding;
  static const chats = _Paths.chats;
  static const settings = _Paths.settings;
  static const trips = _Paths.trips;
  static const more = _Paths.more;
  static const scan = _Paths.scan;
  static const history = _Paths.history;
}

abstract class _Paths {
  _Paths._();
  static const home = '/home';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const chats = '/chats';
  static const settings = '/settings';
  static const trips = '/trips';
  static const more = '/more';
  static const scan = '/scan';
  static const history = '/history';
}
