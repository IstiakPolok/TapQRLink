import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qr_code/app/modules/home/controllers/home_controller.dart';
import 'package:qr_code/app/modules/settings/controllers/revenue_cat_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../res/colors/app_color.dart';
import '../../../../res/components/api_service.dart';
import '../../../../res/components/notification_service.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../../routes/app_pages.dart';
import '../../home/views/nav_bar.dart';
import '../../settings/controllers/profile_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../views/auth_view.dart';
import '../views/change_password_view.dart';
import '../views/otp_verify_view.dart';
import 'notification_controller.dart';

class AuthController extends GetxController {
  final RxString selectedRole = ''.obs;
  final RxBool isDarkMode = false.obs;

  final ApiService apiService = Get.find<ApiService>();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final RevenueCatController revenueCatController = Get.find();

  final RxBool isOtpVerified = false.obs;
  final RxBool isStorageAvailable = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSocialLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isCheckingToken = true.obs;
  final RxBool isLoggedIn = false.obs;
  final RxBool isSignedIn = false.obs;
  final RxString signupEmail = ''.obs;
  final RxString forgetEmail = ''.obs;
  final RxString accessToken = ''.obs;
  final RxString userId = ''.obs;
  final RxString refreshToken = ''.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController setPasswordController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController forgetEmailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final Map<String, String> _inMemoryStorage = {};

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  @override
  void onClose() {
    stopTimer();
    emailController.dispose();
    passwordController.dispose();
    setPasswordController.dispose();
    signupEmailController.dispose();
    forgetEmailController.dispose();
    otpController.dispose();
    super.onClose();
  }

  Future<void> _writeToStorage(String key, String value) async {
    if (isStorageAvailable.value) {
      try {
        await storage.write(key: key, value: value);
        debugPrint('Wrote $key to secure storage: $value');
      } catch (e) {
        debugPrint('Storage write error: $e');
        isStorageAvailable.value = false;
        showCustomSnackBar(
          title: 'Warning',
          message: 'Secure storage unavailable, using in-memory storage',
          backgroundColor: AppColor.orangeColor,
          isSuccess: false,
        );
        _inMemoryStorage[key] = value;
      }
    } else {
      _inMemoryStorage[key] = value;
      debugPrint('Wrote $key to in-memory storage: $value');
    }
  }

  Future<String?> _readFromStorage(String key) async {
    if (isStorageAvailable.value) {
      try {
        final value = await storage.read(key: key);
        debugPrint('Read $key from secure storage: $value');
        return value;
      } catch (e) {
        debugPrint('Storage read error: $e');
        isStorageAvailable.value = false;
        showCustomSnackBar(
          title: 'Warning',
          message:
              'Failed to read from secure storage, using in-memory storage',
          backgroundColor: AppColor.orangeColor,
          isSuccess: false,
        );
        return _inMemoryStorage[key];
      }
    } else {
      final value = _inMemoryStorage[key];
      debugPrint('Read $key from in-memory storage: $value');
      return value;
    }
  }

  Future<void> checkLoginStatus() async {
    try {
      isCheckingToken(true);
      final token = await _readFromStorage('access');
      final refreshToken = await _readFromStorage('refresh');
      final verifyToken = await _readFromStorage('verify');
      debugPrint('Token on app start: $token');

      if (token != null && token.isNotEmpty) {
        accessToken.value = token;

        if (verifyToken == 'yes') {
          isLoggedIn.value = true;
          isSignedIn.value = true;
          debugPrint('Valid token found, user is logged in');
        } else {
          isLoggedIn.value = false;
          isSignedIn.value = true;
          debugPrint('Token found, but verification failed');
        }
      } else if (refreshToken != null && refreshToken.isNotEmpty) {
        final refreshed = await refreshAccessToken(refreshToken);
        if (refreshed) {
          final newToken = await _readFromStorage('access');
          accessToken.value = newToken!;
          isLoggedIn.value = true;
          isSignedIn.value = true;
          debugPrint('Token was refreshed and user is now logged in');
        } else {
          isLoggedIn.value = false;
          debugPrint('Failed to refresh token');
        }
      } else {
        isLoggedIn.value = false;
        debugPrint('No valid token found');
      }
    } catch (e, stackTrace) {
      debugPrint('Check login error: $e\nStack trace: $stackTrace');
      isLoggedIn.value = false;
    } finally {
      isCheckingToken(false);
    }
  }

  Future<bool> refreshAccessToken(String refresh) async {
    try {
      final response = await apiService.refreshToken(refresh);
      if (response['statusCode'] == 200) {
        debugPrint('response __________________ $response');
        final newAccessToken = response['data']['access'];
        await _writeToStorage('access', newAccessToken);
        accessToken.value = newAccessToken;
        debugPrint('New access token: $newAccessToken');
        debugPrint('Token refreshed successfully');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    return _readFromStorage('access');
  }

  Future<void> signInWithGoogle() async {
    try {
      String fcmToken = await _notificationService.getDeviceToken();
      debugPrint('FCM Token: $fcmToken');
      isLoading.value = true;
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        debugPrint(
          ':::::::::::USER EMAIL::::::::::::::::::::::::::::${user.email}',
        );
        debugPrint(
          ':::::::::::USER NAME::::::::::::::::::::::::::::${user.displayName}',
        );
        debugPrint(':::::::::::USER ID::::::::::::::::::::::::::::${user.uid}');

        await signUpWithOther(user.email!, fcmToken);
      }
    } catch (e) {
      debugPrint("Error signing in: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> storeTokens(String accessToken, String refreshToken) async {
    await storage.write(key: 'access', value: accessToken);
    await storage.write(key: 'refresh', value: refreshToken);
  }

  final NotificationService _notificationService = NotificationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUpWithOther(String email, String fcmToken) async {
    isLoading.value = true;
    try {
      final response = await apiService.signUpWithOther(email, fcmToken);

      debugPrint(
        ':::::::::::::::RESPONSE:::::::::::::::::::::${response.body.toString()}',
      );
      debugPrint(
        ':::::::::::::::CODE:::::::::::::::::::::${response.statusCode}',
      );
      debugPrint(
        ':::::::::::::::REQUEST:::::::::::::::::::::${response.request}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final accessToken = responseBody['access'];
        final refreshToken = responseBody['refresh'];
        await storeTokens(accessToken, refreshToken);
        final message = responseBody['message'];
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token received');
        }
        await _writeToStorage('access', accessToken);
        await _writeToStorage('refresh', refreshToken ?? '');
        this.accessToken.value = accessToken;
        this.refreshToken.value = refreshToken ?? '';
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        isSignedIn.value = true;
        await fcmRegister(fcmToken);
        revenueCatController.init();
        Get.to(() => Navbar(), transition: Transition.fadeIn);

        debugPrint(
          ':::::::::::::::responseBody:::::::::::::::::::::$responseBody',
        );
        debugPrint(
          ':::::::::::::::accessToken:::::::::::::::::::::$accessToken',
        );
        debugPrint(
          ':::::::::::::::refreshToken:::::::::::::::::::::$refreshToken',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
      } else {
        showCustomSnackBar(
          title: 'Error',
          message:
              'Login failed: Sign-up failed\nPlease Use Different Username',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Signup failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fcmRegister(String fcmToken) async {
    isLoading.value = true;
    try {
      final token = await storage.read(key: 'access');
      final response = await apiService.fcmRegister(fcmToken, token!);

      debugPrint(':::::::::::::::FCM:::::::::::::::::::::${response.request}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'];
        debugPrint(message);
      } else {
        showCustomSnackBar(
          title: 'Error',
          message: 'Register FCM Token Failed',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Signup failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    debugPrint('Logging in with email: $email');
    try {
      isLoading(true);
      final response = await apiService.login(email, password);
      if (response['statusCode'] == 200) {
        final data = response['data'];
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;
        final userID = data['user_id'] as int?;
        final message = data['message'] ?? 'Login successful';
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token received');
        }
        await _writeToStorage('access', accessToken);
        await _writeToStorage('refresh', refreshToken ?? '');
        await _writeToStorage('user_id', userID.toString());
        this.accessToken.value = accessToken;
        userId.value = userID.toString();
        this.refreshToken.value = refreshToken ?? '';
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        isLoggedIn.value = true;
        isSignedIn.value = true;
        await fcmRegister(await _notificationService.getDeviceToken());
        revenueCatController.init();
        Get.to(() => Navbar(), transition: Transition.fadeIn);
      } else {
        final errorMsg =
            response['data']['errors'] ??
            response['data']['message'] ??
            'Invalid credentials';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'Login failed: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Login failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> signup() async {
    final email = signupEmailController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final mobile = mobileController.text.trim();

    if (firstName.isEmpty) {
      showCustomSnackBar(
        title: 'Warning',
        message: 'First Name is required',
        backgroundColor: AppColor.orangeColor,
        isSuccess: false,
      );
      return;
    }
    if (lastName.isEmpty) {
      showCustomSnackBar(
        title: 'Warning',
        message: 'Last Name is required',
        backgroundColor: AppColor.orangeColor,
        isSuccess: false,
      );
      return;
    }
    if (email.isEmpty) {
      showCustomSnackBar(
        title: 'Warning',
        message: 'Email is required',
        backgroundColor: AppColor.orangeColor,
        isSuccess: false,
      );
      return;
    }
    if (mobile.isEmpty) {
      showCustomSnackBar(
        title: 'Warning',
        message: 'Mobile Number is required',
        backgroundColor: AppColor.orangeColor,
        isSuccess: false,
      );
      return;
    }

    debugPrint('Signing up with email: $email');
    try {
      isLoading(true);
      final response = await apiService.signup(
        firstName,
        lastName,
        email,
        mobile,
      );
      if (response['statusCode'] == 201 || response['statusCode'] == 200) {
        final message = response['data']['message'] ?? 'OTP sent to your email';
        signupEmail.value = email;
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        Get.to(() => OtpVerifyView(), arguments: {'origin': 'Signup'});
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Signup failed';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'Signup failed: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Signup failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> forget() async {
    final email = forgetEmailController.text.trim();
    debugPrint('Forgot password for email: $email');
    try {
      isLoading(true);
      final response = await apiService.forget(email);
      if (response['statusCode'] == 200) {
        final message = response['data']['message'] ?? 'OTP sent to your email';
        forgetEmail.value = email;
        debugPrint(
          'email_______________ $email __________ ${forgetEmail.value} ______________',
        );
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        Get.to(() => const OtpVerifyView(), arguments: {'origin': 'Forget'});
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Request failed';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'Request failed: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Forget password error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Request failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  void updateOtp(String value) {
    isOtpVerified.value = value.isNotEmpty;
    debugPrint('OTP updated, isOtpVerified: ${isOtpVerified.value}');
  }

  Future<void> verifyOtp() async {
    final email = signupEmail.value;
    final otp = otpController.text.trim();
    debugPrint('Verifying OTP for email: $email, OTP: $otp');
    try {
      isLoading(true);
      final response = await apiService.verifyOtp(email, otp);
      if (response['statusCode'] == 200) {
        final data = response['data'];
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;
        final userID = data['user_id'] as int?;
        await _writeToStorage('access', accessToken ?? '');
        await _writeToStorage('refresh', refreshToken ?? '');
        await _writeToStorage('user_id', userID.toString());
        final token = await _readFromStorage('access');
        final refreshTokenValue = await _readFromStorage('refresh');
        final userId = await _readFromStorage('user_id');
        this.accessToken.value = token ?? '';
        this.userId.value = userId ?? '';
        this.refreshToken.value = refreshTokenValue ?? '';
        showCustomSnackBar(
          title: 'Success',
          message: 'Verified. Now set your password.',
          isSuccess: true,
        );
        final origin = Get.arguments?['origin'] as String?;
        Get.to(
          () => ChangePasswordView(),
          transition: Transition.noTransition,
          arguments: {'origin': origin ?? 'Signup'},
        );
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Invalid OTP';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'OTP verification failed: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('OTP verification error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'OTP verification failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> verifyOtpPassword() async {
    final email = forgetEmail.value;
    final otp = otpController.text.trim();
    debugPrint('Verifying OTP for email: $email, OTP: $otp');
    try {
      isLoading(true);
      final response = await apiService.verifyPasswordOtp(email, otp);
      if (response['statusCode'] == 200) {
        final data = response['data'];
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;
        final userID = data['user_id'] as int?;
        await _writeToStorage('access', accessToken ?? '');
        await _writeToStorage('refresh', refreshToken ?? '');
        await _writeToStorage('user_id', userID.toString());
        final token = await _readFromStorage('access');
        final refreshTokenValue = await _readFromStorage('refresh');
        final userId = await _readFromStorage('user_id');
        this.accessToken.value = token ?? '';
        this.userId.value = userId ?? '';
        this.refreshToken.value = refreshTokenValue ?? '';
        showCustomSnackBar(
          title: 'Success',
          message: 'Verified. Now set your password.',
          isSuccess: true,
        );
        final origin = Get.arguments?['origin'] as String?;
        Get.to(
          () => ChangePasswordView(),
          transition: Transition.noTransition,
          arguments: {'origin': origin ?? 'Signup'},
        );
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Invalid OTP';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'OTP verification failed: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('OTP verification error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'OTP verification failed: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> resendOtp() async {
    final email = signupEmail.value;
    debugPrint('Resending OTP for email: $email');
    try {
      isLoading(true);
      final response = await apiService.resendOtp(email);
      if (response['statusCode'] == 200) {
        final message =
            response['data']['message'] ?? 'OTP resent successfully';
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Failed to resend OTP';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'Failed to resend OTP: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Resend OTP error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to resend OTP: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> resendForgetOtp() async {
    final email = forgetEmail.value;
    debugPrint('Resending OTP for email: $email');
    try {
      isLoading(true);
      final response = await apiService.resendForgetOtp(email);
      if (response['statusCode'] == 200) {
        final message =
            response['data']['message'] ?? 'OTP resent successfully';
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Failed to resend OTP';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: 'Failed to resend OTP: $errorMsg',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Resend OTP error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to resend OTP: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> setPassword() async {
    final newPassword = setPasswordController.text;
    final confirmPassword = confirmPasswordController.text;
    final token = accessToken.value;
    debugPrint('Setting password: $newPassword');
    try {
      isLoading.value = true;
      final response = await apiService.setPassword(
        newPassword,
        confirmPassword,
        token,
      );
      if (response['statusCode'] == 200) {
        final data = response['data'];
        final accessToken = data['access'] as String?;
        final refreshToken = data['refresh'] as String?;
        final user = data['user'] as int?;
        final message = data['message'] ?? 'Password set successfully';
        final verify = data['verify'] ?? 'no';
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token received');
        }
        await _writeToStorage('access', accessToken);
        await _writeToStorage('refresh', refreshToken ?? '');
        await _writeToStorage('user', user.toString());
        this.accessToken.value = accessToken;
        this.refreshToken.value = refreshToken ?? '';
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        isSignedIn.value = true;
        isLoggedIn.value = true;
        await fcmRegister(await _notificationService.getDeviceToken());
        final origin = Get.arguments?['origin'] as String?;
        if (origin == 'Signup' && verify == 'no') {
          Get.offAllNamed(Routes.onboarding, arguments: {'origin': 'Signup'});
        } else if (origin == 'Forget' && verify == 'yes') {
          revenueCatController.init();
          Get.to(() => Navbar(), transition: Transition.noTransition);
        }
      } else if (response['statusCode'] == 401) {
        final refresh = refreshToken.value;
        final refreshed = await refreshAccessToken(refresh);
        if (refreshed) {
          final newToken = await getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.setPassword(
              newPassword,
              confirmPassword,
              newToken,
            );
            if (retryResponse['statusCode'] == 200) {
              final data = retryResponse['data'];
              final accessToken = data['access'] as String?;
              final refreshToken = data['refresh'] as String?;
              final user = data['user'] as int?;
              final message =
                  data['message'] ??
                  'Password set successfully after token refresh';
              final verify = data['verify'] ?? 'no';
              if (accessToken == null || accessToken.isEmpty) {
                throw Exception('No access token received after token refresh');
              }
              await _writeToStorage('access', accessToken);
              await _writeToStorage('refresh', refreshToken ?? '');
              await _writeToStorage('user', user.toString());
              this.accessToken.value = accessToken;
              this.refreshToken.value = refreshToken ?? '';
              showCustomSnackBar(
                title: 'Success',
                message: message,
                isSuccess: true,
              );
              isSignedIn.value = true;
              isLoggedIn.value = true;
              await fcmRegister(await _notificationService.getDeviceToken());
              final origin = Get.arguments?['origin'] as String?;
              if (origin == 'Signup' && verify == 'no') {
                Get.offAllNamed(
                  Routes.onboarding,
                  arguments: {'origin': 'Signup'},
                );
              } else if (origin == 'Forget' && verify == 'yes') {
                revenueCatController.init();
                Get.to(() => Navbar(), transition: Transition.noTransition);
              }
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to set password after token refresh';
              errorMessage.value = errorMsg;
              showCustomSnackBar(
                title: 'Error',
                message: errorMsg,
                backgroundColor: AppColor.redColor,
                isSuccess: false,
              );
              Get.toNamed(Routes.auth);
            }
          } else {
            errorMessage.value = 'Failed to retrieve new access token';
            showCustomSnackBar(
              title: 'Error',
              message: errorMessage.value,
              backgroundColor: AppColor.redColor,
              isSuccess: false,
            );
            Get.toNamed(Routes.auth);
          }
        } else {
          errorMessage.value = 'Failed to refresh token. Please log in again.';
          showCustomSnackBar(
            title: 'Error',
            message: errorMessage.value,
            backgroundColor: AppColor.redColor,
            isSuccess: false,
          );
          Get.toNamed(Routes.auth);
        }
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Failed to set password';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          message: errorMsg,
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Set password error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to set password: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword() async {
    final email = forgetEmail.value;
    final newPassword = setPasswordController.text;
    final confirmPassword = confirmPasswordController.text;
    debugPrint('Setting password: $newPassword');
    try {
      isLoading.value = true;
      final response = await apiService.changePassword(
        email,
        newPassword,
        confirmPassword,
      );
      if (response['statusCode'] == 200) {
        final data = response['data'];
        final message = data['message'] as String?;
        showCustomSnackBar(
          title: 'Success',
          message: message!,
          isSuccess: true,
        );
        isSignedIn.value = true;
        isLoggedIn.value = true;
        Get.offAll(
          () => AuthView(),
          transition: Transition.rightToLeftWithFade,
        );
      } else if (response['statusCode'] == 401) {
        final refresh = refreshToken.value;
        final refreshed = await refreshAccessToken(refresh);
        if (refreshed) {
          final newToken = await getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.changePassword(
              email,
              newPassword,
              confirmPassword,
            );
            if (retryResponse['statusCode'] == 200) {
              final data = retryResponse['data'];
              final message = data['message'] as String?;
              showCustomSnackBar(
                title: 'Success',
                message: message!,
                isSuccess: true,
              );
              isSignedIn.value = true;
              isLoggedIn.value = true;
              Get.offAll(
                () => AuthView(),
                transition: Transition.rightToLeftWithFade,
              );
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to change password after token refresh';
              errorMessage.value = errorMsg;
              showCustomSnackBar(
                title: 'Error',
                message: errorMsg,
                backgroundColor: AppColor.redColor,
                isSuccess: false,
              );
              Get.toNamed(Routes.auth);
            }
          } else {
            errorMessage.value = 'Failed to retrieve new access token';
            showCustomSnackBar(
              title: 'Error',
              message: errorMessage.value,
              backgroundColor: AppColor.redColor,
              isSuccess: false,
            );
            Get.toNamed(Routes.auth);
          }
        } else {
          errorMessage.value = 'Failed to refresh token. Please log in again.';
          showCustomSnackBar(
            title: 'Error',
            message: errorMessage.value,
            backgroundColor: AppColor.redColor,
            isSuccess: false,
          );
          Get.toNamed(Routes.auth);
        }
      } else {
        final errorMsg =
            response['data']['error'] ??
            response['data']['message'] ??
            'Failed to change password';
        errorMessage.value = errorMsg;
        showCustomSnackBar(
          title: 'Error',
          duration: 4.seconds,
          message: errorMsg,
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Change password error: $e\nStack trace: $stackTrace');
      errorMessage.value = 'Error: $e';
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to change password: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    debugPrint('Logging out and clearing all data');
    try {
      isLoading.value = true;
      if (Get.isRegistered<RevenueCatController>()) {
        await Get.find<RevenueCatController>().clearData();
      }
      await storage.deleteAll();

      storage.write(key: 'popup', value: 'true');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().storageHistory.erase();
      }

      debugPrint('Cleared all local storage instances');

      try {
        if (await Purchases.isConfigured) {
          await Purchases.logOut();
          debugPrint('RevenueCat logged out');
        }
      } catch (e) {
        debugPrint('RevenueCat logout error: $e');
      }

      await _auth.signOut();
      await googleSignIn.signOut();

      _resetAuthStates();
      _resetHomeStates();
      _resetProfileStates();
      _resetOtherStates();

      Get.offAllNamed(Routes.home);

      showCustomSnackBar(
        title: 'Success',
        message: 'Logged out successfully',
        isSuccess: true,
      );
    } catch (e, stackTrace) {
      debugPrint('Logout error: $e\n$stackTrace');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to logout',
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _resetAuthStates() {
    accessToken.value = '';
    refreshToken.value = '';
    isSignedIn.value = false;
    isLoggedIn.value = false;
    emailController.clear();
    passwordController.clear();
    accessToken.value = '';
    refreshToken.value = '';
    userId.value = '';
    isCheckingToken.value = false;
    isSignedIn.value = false;
    isLoggedIn.value = false;
    isOtpVerified.value = false;
    isStorageAvailable.value = true;
    isLoading.value = false;
    errorMessage.value = '';
    signupEmail.value = '';
    forgetEmail.value = '';
    emailController.clear();
    passwordController.clear();
    setPasswordController.clear();
    signupEmailController.clear();
    forgetEmailController.clear();
    otpController.clear();
    isRemembered.value = false;
    selectedRole.value = '';
    debugPrint('Reset AuthController state');
  }

  void _resetHomeStates() {
    if (Get.isRegistered<HomeController>()) {
      final h = Get.find<HomeController>();

      h.historyItems.clear();
      h.adClickCount.value = 0;
      h.qrCode.value = '';
      h.isScanning.value = false;
      h.selectedIndex.value = 0;
      h.popups.value = false;
      h.sliderValue.value = 50.0;
      h.isScanning.value = false;
      h.isScanning1.value = false;
      h.qrCode.value = '';
      h.notifications.clear();
      h.historyItems.clear();
      h.isLoading.value = false;
      h.errorMessage.value = '';
      h.qrResponse.value = null;
      h.mobileScannerController?.dispose();
      h.mobileScannerController = null;
      debugPrint('Reset HomeController state');

      try {
        h.mobileScannerController?.stop();
        h.mobileScannerController?.dispose();
      } catch (_) {}
      h.mobileScannerController = null;
    }
  }

  void _resetProfileStates() {
    if (Get.isRegistered<ProfileController>()) {
      final p = Get.find<ProfileController>();
      p.profile.value = null;
      p.firstnameController.clear();
      p.firstname.value = '';
      p.lastName.value = '';
      p.mobile.value = '';
      p.profilePicture.value = '';
      p.bio.value = '';
      p.email.value = '';
      p.pickedImage.value = null;
      p.firstnameController.clear();
      p.lastNameController.clear();
      p.mobileController.clear();
      p.bioController.clear();
      p.emailController.clear();
      p.isLoading.value = true;
      p.errorMessage.value = '';
      debugPrint('Reset ProfileController state');
    }
  }

  void _resetOtherStates() {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().notifications.clear();
    }
    if (Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>().count.value = 0;
    }
  }

  void clear() {
    signupEmail.value = '';
    accessToken.value = '';
    refreshToken.value = '';
    isOtpVerified.value = false;
    errorMessage.value = '';
    isLoggedIn.value = false;
    emailController.clear();
    passwordController.clear();
    setPasswordController.clear();
    signupEmailController.clear();
    forgetEmailController.clear();
    otpController.clear();
    debugPrint('Cleared AuthController state');
  }

  final RxBool isRemembered = false.obs;

  Future<void> savePassword() async {
    showCustomSnackBar(
      title: 'Success',
      message: 'Password saved successfully',
      isSuccess: true,
    );
  }

  RxInt secondsRemaining = 60.obs;
  RxString formattedTime = '01:00'.obs;

  Timer? _timer;

  void startTimer() {
    stopTimer();
    secondsRemaining.value = 60;
    _updateFormattedTime();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
        _updateFormattedTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateFormattedTime() {
    final int minutes = secondsRemaining.value ~/ 60;
    final int seconds = secondsRemaining.value % 60;
    formattedTime.value =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void stopTimer() {
    _timer?.cancel();
  }
}
