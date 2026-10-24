import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../../res/components/api_service.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/models/profile.dart';
import 'revenue_cat_controller.dart';

class ProfileController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final AuthController authController = Get.find<AuthController>();

  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  final RxString firstname = ''.obs;
  final RxString lastName = ''.obs;
  final RxString mobile = ''.obs;
  final RxString profilePicture = ''.obs;
  final RxString bio = ''.obs;
  final RxString email = ''.obs;
  Rxn<File> pickedImage = Rxn<File>();

  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('ProfileController initialized');

    firstnameController.text = firstname.value;
    lastNameController.text = lastName.value;
    mobileController.text = mobile.value;
    bioController.text = bio.value;
    emailController.text = email.value;

    firstnameController.addListener(
      () => firstname.value = firstnameController.text,
    );
    lastNameController.addListener(
      () => lastName.value = lastNameController.text,
    );
    mobileController.addListener(() => mobile.value = mobileController.text);
    bioController.addListener(() => bio.value = bioController.text);
    emailController.addListener(() => email.value = emailController.text);
  }

  @override
  void onClose() {
    firstnameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    bioController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void _showSnackBar({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    showCustomSnackBar(title: title, message: message, isSuccess: isSuccess);
  }

  Future<void> _applyProfileData(ProfileModel? prof, String token) async {
    String fname = prof?.firstName ?? '';
    String lname = prof?.lastName ?? '';

    // If API returned empty names, fallback to secure storage
    if (fname.isEmpty) {
      fname = await storage.read(key: 'first_name') ?? '';
    }
    if (lname.isEmpty) {
      lname = await storage.read(key: 'last_name') ?? '';
    }

    final userEmail = (prof?.email != null && prof!.email.isNotEmpty)
        ? prof.email
        : (await storage.read(key: 'email') ?? email.value);

    // If still empty, derive clean name from email address
    if (fname.isEmpty && userEmail.isNotEmpty) {
      final raw = userEmail.split('@').first;
      fname = raw
          .replaceAll(RegExp(r'[\._\-]'), ' ')
          .split(' ')
          .where((s) => s.isNotEmpty)
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      if (fname.isEmpty) fname = 'User';
      await storage.write(key: 'first_name', value: fname);
    }

    firstname.value = fname;
    lastName.value = lname;
    email.value = userEmail;
    bio.value = prof?.bio ?? '';
    mobile.value = prof?.mobileNumber ?? '';
    profilePicture.value = prof?.profilePicture ?? '';

    if (userEmail.isNotEmpty) {
      await storage.write(key: 'email', value: userEmail);
      if (Get.isRegistered<RevenueCatController>()) {
        Get.find<RevenueCatController>().logInUser(userEmail);
      }
    }

    firstnameController.text = fname;
    lastNameController.text = lname;
    emailController.text = userEmail;
    bioController.text = bio.value;
    mobileController.text = mobile.value;

    // If backend had empty first_name, push our name to backend in background
    if ((prof?.firstName == null || prof!.firstName.isEmpty) && fname.isNotEmpty && token.isNotEmpty) {
      try {
        apiService.updateProfileNames(
          firstName: fname,
          lastName: lname,
          token: token,
        );
      } catch (e) {
        debugPrint('Background name sync to backend: $e');
      }
    }
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final token = await storage.read(key: 'access');
      if (token == null) {
        errorMessage.value = 'Please log in again to see profile details';
        return;
      }
      final response = await apiService.getProfile(token);
      if (response['statusCode'] == 200) {
        profile.value = ProfileModel.fromJson(response['data']);
        debugPrint('firstName from API: ${profile.value?.firstName}');
        await _applyProfileData(profile.value, token);
      } else if (response['statusCode'] == 401) {
        final refreshToken = await storage.read(key: 'refresh');
        final refreshed = await authController.refreshAccessToken(
          refreshToken!,
        );
        if (refreshed) {
          final newToken = await authController.getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.getProfile(newToken);
            if (retryResponse['statusCode'] == 200) {
              profile.value = ProfileModel.fromJson(retryResponse['data']);
              debugPrint(
                'firstName after token refresh: ${profile.value?.firstName}',
              );
              await _applyProfileData(profile.value, newToken);
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to fetch profile after token refresh';
              errorMessage.value = errorMsg;
              _showSnackBar(
                title: 'Error',
                message: errorMsg,
                isSuccess: false,
              );
              Get.toNamed(Routes.auth);
            }
          } else {
            errorMessage.value = 'Failed to retrieve new access token';
            _showSnackBar(
              title: 'Error',
              message: errorMessage.value,
              isSuccess: false,
            );
            Get.toNamed(Routes.auth);
          }
        } else {
          errorMessage.value = 'Failed to refresh token. Please log in again.';
          _showSnackBar(
            title: 'Error',
            message: errorMessage.value,
            isSuccess: false,
          );
          Get.toNamed(Routes.auth);
        }
      } else {
        errorMessage.value =
            response['data']['detail'] ?? 'Failed to fetch profile';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error fetching profile: $e';
      debugPrint('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    final token = await storage.read(key: 'access');
    if (token == null) {
      errorMessage.value =
          'Authentication token not found. Please log in again.';
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
      Get.toNamed(Routes.auth);
      return;
    }

    if (pickedImage.value == null && profilePicture.value.isEmpty) {
      errorMessage.value =
          'Please select a profile picture or provide an existing URL.';
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await apiService.updateProfile(
        firstName: firstname.value,
        lastName: lastName.value,
        email: email.value,
        mobile: mobile.value,
        picture: pickedImage.value,
        picture1: profilePicture.value,
        token: token,
      );

      if (response['statusCode'] == 200) {
        profile.value = ProfileModel.fromJson(response['data']);
        debugPrint('firstName: 🚀 ${profile.value?.firstName}');
        firstname.value = profile.value?.firstName ?? '';
        lastName.value = profile.value?.lastName ?? '';
        email.value = profile.value?.email ?? '';
        bio.value = profile.value?.bio ?? '';
        mobile.value = profile.value?.mobileNumber ?? '';
        profilePicture.value = profile.value?.profilePicture ?? '';
        firstnameController.text = firstname.value;
        lastNameController.text = lastName.value;
        emailController.text = email.value;
        bioController.text = bio.value;
        mobileController.text = mobile.value;

        _showSnackBar(
          title: 'Success',
          message: 'Profile updated successfully',
          isSuccess: true,
        );
        Navigator.pop(Get.context!);
      } else if (response['statusCode'] == 401) {
        final refreshToken = await storage.read(key: 'refresh');
        final refreshed = await authController.refreshAccessToken(
          refreshToken!,
        );
        if (refreshed) {
          final newToken = await authController.getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.updateProfile(
              firstName: firstname.value,
              lastName: lastName.value,
              email: email.value,
              mobile: mobile.value,
              picture: pickedImage.value,
              picture1: profilePicture.value,
              token: newToken,
            );
            if (retryResponse['statusCode'] == 200) {
              profile.value = ProfileModel.fromJson(retryResponse['data']);
              debugPrint(
                'firstName after token refresh: 🚀 ${profile.value?.firstName}',
              );
              firstname.value = profile.value?.firstName ?? '';
              lastName.value = profile.value?.lastName ?? '';
              email.value = profile.value?.email ?? '';
              bio.value = profile.value?.bio ?? '';
              mobile.value = profile.value?.mobileNumber ?? '';
              profilePicture.value = profile.value?.profilePicture ?? '';
              firstnameController.text = firstname.value;
              lastNameController.text = lastName.value;
              emailController.text = email.value;
              bioController.text = bio.value;
              mobileController.text = mobile.value;

              _showSnackBar(
                title: 'Success',
                message: 'Profile updated successfully after token refresh',
                isSuccess: true,
              );
              Navigator.pop(Get.context!);
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to update profile after token refresh';
              errorMessage.value = errorMsg;
              _showSnackBar(
                title: 'Error',
                message: errorMsg,
                isSuccess: false,
              );
              Get.toNamed(Routes.auth);
            }
          } else {
            errorMessage.value = 'Failed to retrieve new access token';
            _showSnackBar(
              title: 'Error',
              message: errorMessage.value,
              isSuccess: false,
            );
            Get.toNamed(Routes.auth);
          }
        } else {
          errorMessage.value = 'Failed to refresh token. Please log in again.';
          _showSnackBar(
            title: 'Error',
            message: errorMessage.value,
            isSuccess: false,
          );
          Get.toNamed(Routes.auth);
        }
      } else {
        errorMessage.value =
            response['data']['error'] ?? 'Failed to update profile';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error updating profile: $e';
      debugPrint('Error: $e');
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
