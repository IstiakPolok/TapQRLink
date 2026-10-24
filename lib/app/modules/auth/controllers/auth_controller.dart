import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  final RxBool isGoogleLoading = false.obs;
  final RxBool isAppleLoading = false.obs;
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
          final storedEmail = await _readFromStorage('email');
          if (storedEmail != null && storedEmail.trim().isNotEmpty) {
            revenueCatController.logInUser(storedEmail.trim());
          } else {
            revenueCatController.init();
          }
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
          final storedEmail = await _readFromStorage('email');
          if (storedEmail != null && storedEmail.trim().isNotEmpty) {
            revenueCatController.logInUser(storedEmail.trim());
          } else {
            revenueCatController.init();
          }
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
      isGoogleLoading.value = true;
      isSocialLoading.value = true;
      String fcmToken = '';
      try {
        fcmToken = await _notificationService.getDeviceToken();
        debugPrint('FCM Token: $fcmToken');
      } catch (e) {
        debugPrint('Error getting device token: $e');
      }
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign in was cancelled by user');
        return;
      }

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

      if (user != null && user.email != null) {
        debugPrint(
          ':::::::::::USER EMAIL::::::::::::::::::::::::::::${user.email}',
        );
        debugPrint(
          ':::::::::::USER NAME::::::::::::::::::::::::::::${user.displayName}',
        );
        debugPrint(':::::::::::USER ID::::::::::::::::::::::::::::${user.uid}');

        String? googleFirstName;
        String? googleLastName;
        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          final parts = user.displayName!.trim().split(' ');
          googleFirstName = parts.first;
          if (parts.length > 1) {
            googleLastName = parts.sublist(1).join(' ');
          }
        }

        await signUpWithOther(
          user.email!,
          fcmToken,
          firstName: googleFirstName,
          lastName: googleLastName,
        );
      } else {
        showCustomSnackBar(
          title: 'Error',
          message: 'Failed to retrieve email from Google account',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      showCustomSnackBar(
        title: 'Google Sign In Failed',
        message: 'Could not complete Google Sign-In. Please try again.',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isGoogleLoading.value = false;
      isSocialLoading.value = false;
    }
  }

  Future<void> signInWithApple() async {
    if (isAppleLoading.value || isSocialLoading.value) return;
    try {
      isAppleLoading.value = true;
      isSocialLoading.value = true;

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        showCustomSnackBar(
          title: 'Sign In Unavailable',
          message: 'Apple Sign-In is not supported or available on this device.',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      String? email = credential.email;
      final String userIdentifier = credential.userIdentifier ?? '';

      // 1. Extract Apple name (Only provided on the 1st authorization!)
      String? firstName = credential.givenName;
      String? lastName = credential.familyName;

      // 2. Cache Name & Email if returned (Apple only sends them on the first authorization)
      if (userIdentifier.isNotEmpty) {
        if (firstName != null && firstName.isNotEmpty) {
          await _writeToStorage('apple_first_name_$userIdentifier', firstName);
        } else {
          // Restore cached first name for repeat logins
          firstName = await _readFromStorage('apple_first_name_$userIdentifier');
        }

        if (lastName != null && lastName.isNotEmpty) {
          await _writeToStorage('apple_last_name_$userIdentifier', lastName);
        } else {
          // Restore cached last name for repeat logins
          lastName = await _readFromStorage('apple_last_name_$userIdentifier');
        }

        if (email != null && email.isNotEmpty) {
          await _writeToStorage('apple_email_$userIdentifier', email);
        } else {
          // Restore cached email for repeat logins
          email = await _readFromStorage('apple_email_$userIdentifier');
        }
      }

      // 3. Fallback: Parse identity token JWT for email claim
      if ((email == null || email.isEmpty) && credential.identityToken != null) {
        try {
          final parts = credential.identityToken!.split('.');
          if (parts.length >= 2) {
            final normalized = base64Url.normalize(parts[1]);
            final payloadString = utf8.decode(base64Url.decode(normalized));
            final Map<String, dynamic> payload = jsonDecode(payloadString);
            if (payload['email'] != null &&
                payload['email'].toString().isNotEmpty) {
              email = payload['email'].toString();
              if (userIdentifier.isNotEmpty) {
                await _writeToStorage('apple_email_$userIdentifier', email);
              }
            }
          }
        } catch (e) {
          debugPrint('Error decoding Apple identity token payload: $e');
        }
      }

      // 4. Fallback: Use stable private relay email constructed from Apple userIdentifier
      if (email == null || email.isEmpty) {
        if (userIdentifier.isNotEmpty) {
          email = '$userIdentifier@privaterelay.appleid.com';
        } else {
          email =
              'apple_user_${DateTime.now().millisecondsSinceEpoch}@privaterelay.appleid.com';
        }
      }

      // 5. Fallback for Name: If Apple didn't return names and cache is empty, derive from email
      if ((firstName == null || firstName.trim().isEmpty) && email.isNotEmpty) {
        final emailPrefix = email.split('@').first;
        final formatted = emailPrefix
            .replaceAll(RegExp(r'[\._\-]'), ' ')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' ');
        firstName = formatted.isNotEmpty ? formatted : 'Apple User';
        if (userIdentifier.isNotEmpty) {
          await _writeToStorage('apple_first_name_$userIdentifier', firstName);
        }
      }

      final String fullName = [firstName, lastName]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join(' ')
          .trim();

      if (firstName != null && firstName.isNotEmpty) {
        await _writeToStorage('first_name', firstName);
      }
      if (lastName != null && lastName.isNotEmpty) {
        await _writeToStorage('last_name', lastName);
      }

      debugPrint(
        'Apple Sign-In: firstName="$firstName", lastName="$lastName", fullName="$fullName", email="$email", userIdentifier="$userIdentifier"',
      );

      // Optional: Firebase sign-in with Apple credential (non-blocking if provider unconfigured)
      if (credential.identityToken != null) {
        try {
          final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
          final AuthCredential authCredential = oAuthProvider.credential(
            idToken: credential.identityToken,
            rawNonce: null,
          );
          final userCredential = await _auth.signInWithCredential(authCredential);
          if (fullName.isNotEmpty) {
            await userCredential.user?.updateDisplayName(fullName);
          }
          debugPrint('Successfully authenticated with Firebase via Apple (name: $fullName)');
        } catch (e) {
          debugPrint('Firebase Apple sign-in optional step: $e');
        }
      }

      // Get FCM device token
      String fcmToken = '';
      try {
        fcmToken = await _notificationService.getDeviceToken();
        debugPrint('FCM Token for Apple user: $fcmToken');
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // Authenticate with backend API
      await signUpWithOther(
        email,
        fcmToken,
        firstName: firstName,
        lastName: lastName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('Apple Sign-In authorization error: ${e.code} - ${e.message}');
      if (e.code != AuthorizationErrorCode.canceled) {
        showCustomSnackBar(
          title: 'Sign In Failed',
          message: e.message.isNotEmpty
              ? e.message
              : 'Sign in with Apple failed. Please check your Apple ID settings and try again.',
          backgroundColor: AppColor.redColor,
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      showCustomSnackBar(
        title: 'Sign In Failed',
        message: 'Could not complete Apple Sign-In. Please try again.',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
    } finally {
      isAppleLoading.value = false;
      isSocialLoading.value = false;
    }
  }

  Future<void> storeTokens(String accessToken, String refreshToken) async {
    await storage.write(key: 'access', value: accessToken);
    await storage.write(key: 'refresh', value: refreshToken);
  }

  final NotificationService _notificationService = NotificationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS
        ? '1042882535852-f186qqj66a3ul650cakldll1aj1n29rv.apps.googleusercontent.com'
        : null,
  );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUpWithOther(
    String email,
    String fcmToken, {
    String? firstName,
    String? lastName,
  }) async {
    isLoading.value = true;
    try {
      final response = await apiService.signUpWithOther(
        email,
        fcmToken,
        firstName: firstName,
        lastName: lastName,
      );

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
        await _writeToStorage('email', email.trim());
        this.accessToken.value = accessToken;
        this.refreshToken.value = refreshToken ?? '';

        if (firstName != null && firstName.trim().isNotEmpty) {
          await _writeToStorage('first_name', firstName.trim());
        }
        if (lastName != null && lastName.trim().isNotEmpty) {
          await _writeToStorage('last_name', lastName.trim());
        }
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          if (firstName != null && firstName.trim().isNotEmpty) {
            profileController.firstname.value = firstName.trim();
            profileController.firstnameController.text = firstName.trim();
          }
          if (lastName != null && lastName.trim().isNotEmpty) {
            profileController.lastName.value = lastName.trim();
            profileController.lastNameController.text = lastName.trim();
          }
        }

        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        isSignedIn.value = true;
        await fcmRegister(fcmToken);
        await revenueCatController.logInUser(email.trim());
        Get.offAll(() => Navbar(), transition: Transition.fadeIn);

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
    if (fcmToken.isEmpty) {
      debugPrint('FCM Token is empty, skipping registration.');
      return;
    }
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
        await _writeToStorage('email', email);
        this.accessToken.value = accessToken;
        userId.value = userID.toString();
        this.refreshToken.value = refreshToken ?? '';
        showCustomSnackBar(title: 'Success', message: message, isSuccess: true);
        isLoggedIn.value = true;
        isSignedIn.value = true;
        await fcmRegister(await _notificationService.getDeviceToken());
        await revenueCatController.logInUser(email);
        Get.offAll(() => Navbar(), transition: Transition.fadeIn);
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
        if (email.isNotEmpty) {
          await _writeToStorage('email', email.trim());
        }
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
        if (email.isNotEmpty) {
          await _writeToStorage('email', email.trim());
        }
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
        final storedEmail = await _readFromStorage('email');
        if (storedEmail != null && storedEmail.trim().isNotEmpty) {
          await revenueCatController.logInUser(storedEmail.trim());
        } else {
          revenueCatController.init();
        }
        final origin = Get.arguments?['origin'] as String?;
        if (origin == 'Signup' && verify == 'no') {
          Get.offAllNamed(Routes.onboarding, arguments: {'origin': 'Signup'});
        } else if (origin == 'Forget' && verify == 'yes') {
          Get.offAll(() => Navbar(), transition: Transition.noTransition);
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
              final storedEmail = await _readFromStorage('email');
              if (storedEmail != null && storedEmail.trim().isNotEmpty) {
                await revenueCatController.logInUser(storedEmail.trim());
              } else {
                revenueCatController.init();
              }
              final origin = Get.arguments?['origin'] as String?;
              if (origin == 'Signup' && verify == 'no') {
                Get.offAllNamed(
                  Routes.onboarding,
                  arguments: {'origin': 'Signup'},
                );
              } else if (origin == 'Forget' && verify == 'yes') {
                Get.offAll(() => Navbar(), transition: Transition.noTransition);
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

  Future<void> deleteAccount() async {
    debugPrint('Deleting account and clearing all data');
    try {
      isLoading.value = true;

      // 1. Call Backend DELETE /delete-account/ API
      String? access = await storage.read(key: 'access');
      String? refresh = await storage.read(key: 'refresh');

      if (access != null && access.isNotEmpty) {
        var response = await apiService.deleteAccount(
          accessToken: access,
          refreshToken: refresh ?? '',
        );

        // If 401 Unauthorized, try refreshing token once
        if (response['statusCode'] == 401 &&
            refresh != null &&
            refresh.isNotEmpty) {
          final refreshed = await refreshAccessToken(refresh);
          if (refreshed) {
            access = await storage.read(key: 'access');
            if (access != null && access.isNotEmpty) {
              response = await apiService.deleteAccount(
                accessToken: access,
                refreshToken: refresh,
              );
            }
          }
        }

        debugPrint(
          'Delete account API response status: ${response['statusCode']}',
        );
        if (response['statusCode'] != 200 &&
            response['statusCode'] != 204 &&
            response['statusCode'] != 201 &&
            response['statusCode'] != 202) {
          final errorMsg = response['data']?['detail'] ??
              response['data']?['error'] ??
              response['data']?['message'] ??
              'Failed to delete account on server.';
          debugPrint('Backend delete account error: $errorMsg');
        }
      }

      // 2. Delete Firebase Auth user if present
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          await user.delete();
          debugPrint('Firebase user deleted successfully');
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase delete user error code: ${e.code}');
        if (e.code == 'requires-recent-login') {
          showCustomSnackBar(
            title: 'Action Required',
            message:
                'Please re-authenticate / log in again to delete your account.',
            isSuccess: false,
          );
          await logout();
          return;
        }
      } catch (e) {
        debugPrint('Firebase user delete error: $e');
      }

      // Perform local logout / cleanup steps
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


      try {
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google Sign-in signout error: $e');
      }

      _resetAuthStates();
      _resetHomeStates();
      _resetProfileStates();
      _resetOtherStates();

      Get.offAllNamed(Routes.home);

      showCustomSnackBar(
        title: 'Success',
        message: 'Account deleted successfully',
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to delete account. Please try again.',
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
      final settings = Get.find<SettingsController>();
      settings.count.value = 0;
      settings.isPremium.value = false;
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
