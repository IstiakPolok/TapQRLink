import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../res/app_url/app_url.dart';
import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../res/components/api_service.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/show_custom_snack_bar.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/revenue_cat_controller.dart';
import '../../settings/models/notification_model.dart';
import '../../settings/views/subscription_view.dart';
import '../models/guide_model.dart';
import '../models/history_model.dart';
import '../views/guide_view.dart';
import '../views/qr_code_view.dart';

class HomeController extends GetxController {
  final ApiService apiService = Get.find();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final AuthController authController = Get.find();
  final RevenueCatController revenueCatController = Get.find();

  final RxInt selectedIndex = 0.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxList<HistoryModel> historyItems = <HistoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final qrResponse = Rxn<Map<String, dynamic>>();
  final popups = false.obs;
  final sliderValue = 50.0.obs;
  final isScanning = false.obs;
  final isScanning1 = false.obs;
  final qrCode = ''.obs;
  final Rx<Image> selectedImage = Rx<Image>(
    Image.asset(ImageAssets.qrCode, fit: BoxFit.contain),
  );
  final isPlane = false.obs;
  final RxInt adClickCount = 1.obs;
  final String adClickCountKey = 'ad_click_count';

  Future<void> getCheckPopup() async {
    final popup = await storage.read(key: 'popup');
    if (popup.toString() == 'true') {
      popups.value = true;
    }
  }

  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;
  var isBannerLoaded = false.obs;
  var isRewardedLoaded = false.obs;

  // Real AdMob iOS Ad Unit IDs (Production)
  static const String _iosBannerId = 'ca-app-pub-8492413081634752/2175980736';
  static const String _iosInterstitialId = 'ca-app-pub-8492413081634752/6577318220';
  static const String iosRewardedId = 'ca-app-pub-8492413081634752/6633158542';

  // Google Test IDs (Used in debug/development mode to prevent publisher errors and avoid invalid traffic)
  static const String _iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosTestInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String _iosTestRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  // Android Test IDs (Replace with real Android ad units when created)
  static const String _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  String get bannerId => Platform.isAndroid
      ? _androidBannerId
      : (kDebugMode ? _iosTestBannerId : _iosBannerId);

  String get interstitialId => Platform.isAndroid
      ? _androidInterstitialId
      : (kDebugMode ? _iosTestInterstitialId : _iosInterstitialId);

  String get rewardedId => Platform.isAndroid
      ? _androidRewardedId
      : (kDebugMode ? _iosTestRewardedId : iosRewardedId);

  void loadBanner() {
    bannerAd?.dispose();
    isBannerLoaded.value = false;
    bannerAd = BannerAd(
      adUnitId: bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ BannerAd loaded successfully');
          isBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('❌ BannerAd failed to load: code ${err.code}, message: ${err.message}');
          ad.dispose();
          isBannerLoaded.value = false;
        },
      ),
    )..load();
  }

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ InterstitialAd loaded successfully');
          interstitialAd = ad;
          interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial dismissed, preloading next ad');
              ad.dispose();
              interstitialAd = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('❌ Interstitial failed to show: ${err.message}');
              ad.dispose();
              interstitialAd = null;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('❌ InterstitialAd failed to load: code ${err.code}, message: ${err.message}');
          interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitial() {
    if (interstitialAd != null) {
      interstitialAd!.show();
    } else {
      debugPrint("Interstitial Ad not ready yet, loading new ad...");
      loadInterstitial();
    }
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ RewardedAd loaded successfully');
          rewardedAd = ad;
          isRewardedLoaded.value = true;
          rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded ad dismissed, preloading next ad');
              ad.dispose();
              rewardedAd = null;
              isRewardedLoaded.value = false;
              loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('❌ Rewarded ad failed to show: ${err.message}');
              ad.dispose();
              rewardedAd = null;
              isRewardedLoaded.value = false;
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('❌ RewardedAd failed to load: code ${err.code}, message: ${err.message}');
          rewardedAd = null;
          isRewardedLoaded.value = false;
        },
      ),
    );
  }

  void showRewarded({required void Function(RewardItem reward) onUserEarnedReward}) {
    if (rewardedAd != null) {
      rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          onUserEarnedReward(reward);
        },
      );
    } else {
      debugPrint("Rewarded Ad not ready yet, loading new ad...");
      loadRewarded();
    }
  }

  ms.MobileScannerController? mobileScannerController;

  late img.Image previousImage;

  void changePage(int index) => selectedIndex.value = index;

  void initializeScanner() {
    mobileScannerController?.dispose();
    mobileScannerController = ms.MobileScannerController(autoStart: false);
  }

  @override
  void onReady() {
    super.onReady();
    if (!popups.value) {
      Future.delayed(Duration(milliseconds: 500), () {});
    }
  }

  void safeBack() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Navigator.pop(Get.context!);
  }

  @override
  void onClose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAd?.dispose();
    mobileScannerController?.dispose();
    mobileScannerController = null;
    super.onClose();
  }

  void increaseValue() {
    if (sliderValue.value < 90) {
      sliderValue.value += 10;
      updateCameraZoom();
    }
  }

  void decreaseValue() {
    if (sliderValue.value > 0) {
      sliderValue.value -= 10;
      updateCameraZoom();
    }
  }

  void updateSliderValue(double value) {
    sliderValue.value = value;
    updateCameraZoom();
  }

  void updateCameraZoom() {
    if (isScanning.value && mobileScannerController != null) {
      try {
        final double zoomScale = sliderValue.value / 100.0;
        mobileScannerController!.setZoomScale(zoomScale);
      } catch (e) {
        debugPrint('Failed to set zoom: $e');
      }
    }
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      showCustomSnackBar(
        title: 'Camera Access Needed',
        message:
            'Camera permission is required to scan QR codes. Please enable it in Settings.',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
      await openAppSettings();
      return false;
    }

    showCustomSnackBar(
      title: 'Permission Denied',
      message: 'Camera access is required to scan QR codes',
      backgroundColor: AppColor.redColor,
      isSuccess: false,
    );
    return false;
  }

  final storageHistory = GetStorage();
  final historyKey = 'history';

  RxList<dynamic> historyList = <dynamic>[].obs;

  Future<void> loadHistory() async {
    final storedHistory = storageHistory.read(historyKey) ?? [];
    historyList.value = storedHistory;
  }

  Future<void> onQrCodeScanned(String scannedLink) async {
    if (scannedLink.isEmpty) {
      debugPrint("Invalid QR code link");
      return;
    }

    final scannedAt = DateTime.now();

    final historyData = {
      'link': scannedLink,
      'scanned_at': scannedAt.toIso8601String(),
    };

    await addHistory(historyData);

    debugPrint("Scanned link added to history: $scannedLink at $scannedAt");
  }

  final String countKey = 'scan_count';

  Future<void> loadScanCount() async {
    var storedValue = await storage.read(key: countKey);
    if (storedValue != null) {
      adClickCount.value = int.tryParse(storedValue.toString()) ?? 0;
    } else {
      adClickCount.value = 0;
    }
  }

  Future<void> loadAdClickCount() async {
    var storedValue = await storage.read(key: adClickCountKey);
    if (storedValue != null) {
      adClickCount.value = int.tryParse(storedValue.toString()) ?? 0;
    }
  }

  Future<void> incrementAdClickCount() async {
    adClickCount.value++;
    await storage.write(
      key: adClickCountKey,
      value: adClickCount.value.toString(),
    );
  }

  Future<void> handleScan() async {
    if (adClickCount.value >= 3 && revenueCatController.renewalDate.isEmpty) {
      showDialog();
      return;
    } else if (authController.isLoggedIn.value ||
        authController.isSignedIn.value) {
      await scanImageFromFile();
    } else {
      await scanImageFromFile1();
    }
  }

  void showDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Limit Reached',
          style: TextStyle(
            fontFamily: 'Nunito Sans',
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: Get.isDarkMode ? AppColor.whiteColor : AppColor.textColor,
          ),
        ),
        content: Text(
          'Please Upgrade to Premium to\nContinue Scanning Images',
          style: TextStyle(
            fontFamily: 'Nunito Sans',
            fontSize: 16.sp,
            color: Get.isDarkMode ? AppColor.whiteColor : AppColor.textColor,
          ),
        ),
        backgroundColor: Get.isDarkMode
            ? AppColor.darkThemeColor
            : AppColor.backgroundColor,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomButton(
                onPress: () async {
                  Navigator.of(Get.context!).pop();
                },
                title: 'Cancel',
                textColor: AppColor.defaultColor,
                height: 32,
                width: 84,
                fontSize: 12,
                borderColor: AppColor.defaultColor,
                buttonColor: Get.isDarkMode == false
                    ? AppColor.backgroundColor
                    : AppColor.darkThemeColor,
              ),
              CustomButton(
                onPress: () async {
                  authController.isSignedIn.value ||
                          authController.isLoggedIn.value
                      ? Get.to(SubscriptionView())
                      : Get.toNamed(Routes.auth);
                },
                title: 'Upgrade',
                height: 32,
                width: 84,
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> getHistory() async {
    return storageHistory.read(historyKey) ?? [];
  }

  Future<void> addHistory(Map<String, dynamic> historyData) async {
    try {
      List<dynamic> historyList = storageHistory.read(historyKey) ?? [];

      String newId = DateTime.now().millisecondsSinceEpoch.toString();

      historyData['id'] = newId;
      historyList.insert(0, historyData);

      if (historyList.length > 3) {
        historyList.removeLast();
      }

      await storageHistory.write(historyKey, historyList);

      this.historyList.value = historyList;
      debugPrint("History added: $historyData");
    } catch (e) {
      debugPrint("Error adding history: $e");
    }
  }

  Future<void> removeHistoryById(String idToRemove) async {
    try {
      List<dynamic> historyList = storageHistory.read('history') ?? [];

      historyList.removeWhere((historyItem) => historyItem['id'] == idToRemove);

      await storageHistory.write('history', historyList);

      historyItems.removeWhere((item) => item.id == int.tryParse(idToRemove));
      historyItems.refresh();

      debugPrint("History with ID '$idToRemove' removed.");
    } catch (e) {
      debugPrint("Error removing history: $e");
      _showSnackBar(
        title: 'Error',
        message: 'Failed to delete history: $e',
        isSuccess: false,
      );
    }
  }

  Future<void> updateHistoryOnLogin() async {
    final token = await storage.read(key: 'access');
    if (token == null) {
      errorMessage.value =
          'Authentication token not found. Please log in again.';
      showCustomSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
      Get.toNamed(Routes.auth);
      return;
    }

    try {
      List<dynamic> historyList = await getHistory();
      if (historyList.isEmpty) return;

      for (var history in List.from(historyList)) {
        final link = history['link'];

        DateTime? scannedAt;
        try {
          scannedAt = history['scanned_at'] != null
              ? DateTime.parse(history['scanned_at'])
              : DateTime.now();
        } catch (e) {
          scannedAt = DateTime.now();
          debugPrint('Date parsing failed for $link, using current time.');
        }
        final response = await apiService.updateHistory(link, scannedAt, token);
        debugPrint('Response to: $response');

        final int statusCode = response['statusCode'] ?? 0;

        if (statusCode == 201) {
          debugPrint('History updated successfully: $link');
          removeHistoryById(history['id'].toString());
        } else if (statusCode == 401) {
          final refreshToken = await storage.read(key: 'refresh');
          if (refreshToken == null) {
            Get.toNamed(Routes.auth);
            return;
          }

          final refreshed = await authController.refreshAccessToken(
            refreshToken,
          );
          if (refreshed) {
            final newToken = await authController.getAccessToken();
            if (newToken != null) {
              final retryResponse = await apiService.updateHistory(
                link,
                scannedAt,
                newToken,
              );

              if (retryResponse['statusCode'] == 201) {
                debugPrint('History updated successfully after refresh: $link');
                removeHistoryById(history['id'].toString());
              } else {
                final errorData = retryResponse['data'] ?? {};
                final errorMsg =
                    errorData['non_field_errors'] ??
                    errorData['message'] ??
                    errorData['detail'] ??
                    errorData['error'] ??
                    'Failed to update after refresh';

                errorMessage.value = errorMsg.toString();
                showCustomSnackBar(
                  title: 'Error',
                  message: errorMessage.value,
                  isSuccess: false,
                );
              }
            }
          } else {
            errorMessage.value = 'Session expired. Please log in again.';
            showCustomSnackBar(
              title: 'Error',
              message: errorMessage.value,
              isSuccess: false,
            );
            Get.toNamed(Routes.auth);
            return;
          }
        } else {
          final errorData = response['data'] ?? {};
          final errorMsg =
              errorData['non_field_errors'] ??
              errorData['message'] ??
              errorData['detail'] ??
              errorData['error'] ??
              'Failed to update history';

          debugPrint('Failed to update history: $link - $errorMsg');
          errorMessage.value = errorMsg.toString();
        }
      }
    } catch (e) {
      debugPrint('Critical error during history sync: $e');
      errorMessage.value = 'Connection error: $e';
    }
  }

  Future<void> startScanning() async {
    if (isScanning.value || isScanning1.value) return;

    final hasPermission = await requestCameraPermission();
    if (!hasPermission) {
      isScanning.value = false;
      isScanning1.value = false;
      return;
    }

    try {
      if (mobileScannerController == null) {
        initializeScanner();
      }
      isScanning.value = true;
      isScanning1.value = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (mobileScannerController != null) {
            await mobileScannerController!.start();
            updateCameraZoom();
          }
        } catch (e) {
          debugPrint('Error starting camera in post-frame callback: $e');
          isScanning.value = false;
          isScanning1.value = false;
          showCustomSnackBar(
            title: 'Scanner Error',
            message: 'Could not start camera preview: $e',
            backgroundColor: AppColor.redColor,
            isSuccess: false,
          );
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize scanner: $e');
      isScanning.value = false;
      isScanning1.value = false;
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to start scanner: $e',
        backgroundColor: AppColor.redColor,
        isSuccess: false,
      );
      initializeScanner();
    }
  }

  void stopScanning() {
    try {
      mobileScannerController?.stop();
    } catch (e) {
      debugPrint('Failed to stop scanner: $e');
    } finally {
      isScanning.value = false;
      isScanning1.value = false;
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showCustomSnackBar(
      title: 'Success',
      message: 'Link copied to clipboard',
      isSuccess: true,
    );
  }

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    loadHistory();
    loadBanner();
    loadInterstitial();
    loadRewarded();
    initializeScanner();
    loadScanCount();
    loadAdClickCount();
    debugPrint('NotificationController initialized');
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

  var nextPageUrl = RxnString();

  Future<void> fetchHistory({bool isLoadMore = false}) async {
    if (isLoading.value) return;

    try {
      final token = await storage.read(key: 'access');
      if (token == null || token.isEmpty) {
        debugPrint("No access token found, skipping fetchHistory API request.");
        return;
      }

      if (!isLoadMore) {
        isLoading.value = true;
        historyItems.clear();
        nextPageUrl.value = null;
      } else {
        if (nextPageUrl.value == null) return;
        isLoading.value = true;
      }

      final String targetUrl = isLoadMore
          ? nextPageUrl.value!
          : AppUrl.historyUrl;

      debugPrint("🚀 Requesting URL: $targetUrl");

      final response = await apiService.getHistory(token, url: targetUrl);

      if (response['statusCode'] == 200) {
        final data = response['data'];

        nextPageUrl.value = data['next'];

        final List<HistoryModel> fetched = (data['results'] as List)
            .map((e) => HistoryModel.fromJson(e))
            .toList();

        if (isLoadMore) {
          historyItems.addAll(fetched);
        } else {
          historyItems.assignAll(fetched);
        }
      } else if (response['statusCode'] == 401) {
        await _handleTokenRefresh(isLoadMore);
        return;
      } else {
        _handleErrorResponse(response['data']);
      }
    } catch (e) {
      _handleErrorResponse({'error': e.toString()});
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleTokenRefresh(bool isLoadMore) async {
    final refreshToken = await storage.read(key: 'refresh');

    if (refreshToken == null) {
      _handleAuthError('Session expired. Please log in again.');
      return;
    }

    final refreshed = await authController.refreshAccessToken(refreshToken);

    if (refreshed) {
      final newToken = await authController.getAccessToken();
      if (newToken != null) {
        await fetchHistory(isLoadMore: isLoadMore);
      } else {
        _handleAuthError('Failed to retrieve new access token.');
      }
    } else {
      _handleAuthError('Failed to refresh session. Please log in again.');
    }
  }

  void _handleErrorResponse(Map<String, dynamic> data) {
    final errorMsg =
        data['non_field_errors']?.toString() ??
        data['message']?.toString() ??
        data['detail']?.toString() ??
        data['error']?.toString() ??
        'An unknown error occurred';

    errorMessage.value = errorMsg;
    showCustomSnackBar(title: 'Error', message: errorMsg, isSuccess: false);
  }

  void _handleAuthError(String msg) {
    errorMessage.value = msg;
    showCustomSnackBar(title: 'Error', message: msg, isSuccess: false);
    Get.offAllNamed(Routes.auth);
  }

  Future<void> _launchLink(String url) async {
    try {
      final Uri linkLaunchUri = Uri.parse(url);

      if (await canLaunchUrl(linkLaunchUri)) {
        await launchUrl(linkLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(linkLaunchUri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      debugPrint('Error launching link: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'Could not open link',
        isSuccess: false,
      );
    }
  }

  Future<void> showHistoryDetails(int historyId) async {
    try {
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

      final response = await apiService.getHistoryById(historyId, token);
      if (response['statusCode'] == 200) {
        final history = HistoryModel.fromJson(response['data']);
        final index = historyItems.indexWhere((h) => h.id == historyId);
        if (index != -1) {
          historyItems[index] = history;
          historyItems.refresh();
        }
        Get.dialog(
          AlertDialog(
            title: Text(
              'QR Code Details',
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
                color: Get.isDarkMode
                    ? AppColor.whiteColor
                    : AppColor.textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(history.image!),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () => _launchLink(history.link),
                  child: Text(
                    'Link: ${history.link}',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontSize: 16.sp,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Scanned at: ${DateFormat('hh.mm a, dd MMMM yyyy').format(history.scannedAt)}',
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontSize: 14.sp,
                    color: Get.isDarkMode
                        ? AppColor.whiteColor
                        : AppColor.textColor,
                  ),
                ),
              ],
            ),
            backgroundColor: Get.isDarkMode
                ? AppColor.darkThemeColor
                : AppColor.backgroundColor,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(Get.context!),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    color: AppColor.viewColor,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (response['statusCode'] == 401) {
        final refreshToken = await storage.read(key: 'refresh');
        final refreshed = await authController.refreshAccessToken(
          refreshToken!,
        );
        if (refreshed) {
          final newToken = await authController.getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.getHistoryById(
              historyId,
              newToken,
            );
            if (retryResponse['statusCode'] == 200) {
              final history = HistoryModel.fromJson(retryResponse['data']);
              final index = historyItems.indexWhere((h) => h.id == historyId);
              if (index != -1) {
                historyItems[index] = history;
                historyItems.refresh();
              }
              Get.dialog(
                AlertDialog(
                  title: Text(
                    'QR Code Details',
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Get.isDarkMode
                          ? AppColor.whiteColor
                          : AppColor.textColor,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(history.image!),
                      SizedBox(height: 10.h),
                      GestureDetector(
                        onTap: () => _launchLink(history.link),
                        child: Text(
                          'Link: ${history.link}',
                          style: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontSize: 16.sp,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Scanned at: ${DateFormat('hh.mm a, dd MMMM yyyy').format(history.scannedAt)}',
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 14.sp,
                          color: Get.isDarkMode
                              ? AppColor.whiteColor
                              : AppColor.textColor,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Get.isDarkMode
                      ? AppColor.darkThemeColor
                      : AppColor.backgroundColor,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(Get.context!),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          color: AppColor.viewColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to fetch history details after token refresh';
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
            response['data']['error'] ?? 'Failed to fetch history details';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error fetching history details: $e';
      debugPrint('Error: $e');
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
    }
  }

  Future<void> deleteHistory(int historyId) async {
    try {
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
      final response = await apiService.deleteHistory(historyId, token);
      if (response['statusCode'] == 200 || response['statusCode'] == 204) {
        historyItems.removeWhere((h) => h.id == historyId);
        historyItems.refresh();
        _showSnackBar(
          title: 'Success',
          message: 'History item deleted successfully',
          isSuccess: true,
        );
      } else if (response['statusCode'] == 401) {
        final refreshToken = await storage.read(key: 'refresh');
        final refreshed = await authController.refreshAccessToken(
          refreshToken!,
        );
        if (refreshed) {
          final newToken = await authController.getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.deleteHistory(
              historyId,
              newToken,
            );
            if (retryResponse['statusCode'] == 200 ||
                retryResponse['statusCode'] == 204) {
              historyItems.removeWhere((h) => h.id == historyId);
              historyItems.refresh();
              _showSnackBar(
                title: 'Success',
                message:
                    'History item deleted successfully after token refresh',
                isSuccess: true,
              );
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to delete history item after token refresh';
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
            response['data']['error'] ?? 'Failed to delete history item';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error deleting history item: $e';
      debugPrint('Error: $e');
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
    }
  }

  Future<void> showNotificationDetails(int notificationId) async {
    try {
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

      final response = await apiService.getNotificationById(
        notificationId,
        token,
      );
      if (response['statusCode'] == 200) {
        final notification = NotificationModel.fromJson(response['data']);
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notification;
          notifications.refresh();
        }
        Get.dialog(
          AlertDialog(
            title: Text(
              notification.title,
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
                color: Get.isDarkMode
                    ? AppColor.whiteColor
                    : AppColor.textColor,
              ),
            ),
            content: Text(
              notification.message,
              style: TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 16.sp,
                color: Get.isDarkMode
                    ? AppColor.whiteColor
                    : AppColor.textColor,
              ),
            ),
            backgroundColor: Get.isDarkMode
                ? AppColor.darkThemeColor
                : AppColor.backgroundColor,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(Get.context!),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Nunito Sans',
                    color: AppColor.viewColor,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (response['statusCode'] == 401) {
        final refreshToken = await storage.read(key: 'refresh');
        final refreshed = await authController.refreshAccessToken(
          refreshToken!,
        );
        if (refreshed) {
          final newToken = await authController.getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.getNotificationById(
              notificationId,
              newToken,
            );
            if (retryResponse['statusCode'] == 200) {
              final notification = NotificationModel.fromJson(
                retryResponse['data'],
              );
              final index = notifications.indexWhere(
                (n) => n.id == notificationId,
              );
              if (index != -1) {
                notifications[index] = notification;
                notifications.refresh();
              }
              Get.dialog(
                AlertDialog(
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Get.isDarkMode
                          ? AppColor.whiteColor
                          : AppColor.textColor,
                    ),
                  ),
                  content: Text(
                    notification.message,
                    style: TextStyle(
                      fontFamily: 'Nunito Sans',
                      fontSize: 16.sp,
                      color: Get.isDarkMode
                          ? AppColor.whiteColor
                          : AppColor.textColor,
                    ),
                  ),
                  backgroundColor: Get.isDarkMode
                      ? AppColor.darkThemeColor
                      : AppColor.backgroundColor,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(Get.context!),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          color: AppColor.viewColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to fetch notification details after token refresh';
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
            response['data']['error'] ?? 'Failed to fetch notification details';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error fetching notification details: $e';
      debugPrint('Error: $e');
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
    }
  }

  var nextNotificationUrl = RxnString();

  Future<void> fetchNotifications({bool isLoadMore = false}) async {
    if (isLoading.value) return;

    try {
      if (!isLoadMore) {
        isLoading.value = true;
        notifications.clear();
        nextNotificationUrl.value = null;
      } else {
        if (nextNotificationUrl.value == null) return;
        isLoading.value = true;
      }

      final token = await storage.read(key: 'access');

      final String targetUrl = isLoadMore
          ? nextNotificationUrl.value!
          : AppUrl.notificationsUrl;

      final response = await apiService.getNotifications(
        token!,
        url: targetUrl,
      );

      if (response['statusCode'] == 200) {
        final data = response['data'];

        nextNotificationUrl.value = data['next'];

        final List<NotificationModel> fetchedItems = (data['results'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        if (isLoadMore) {
          notifications.addAll(fetchedItems);
        } else {
          notifications.assignAll(fetchedItems);
        }
      } else if (response['statusCode'] == 401) {
        await _handleNotificationTokenRefresh(isLoadMore);
      } else {
        _handleErrorResponse(response['data']);
      }
    } catch (e) {
      debugPrint('Notification Fetch Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleNotificationTokenRefresh(bool isLoadMore) async {
    final refreshToken = await storage.read(key: 'refresh');
    final refreshed = await authController.refreshAccessToken(refreshToken!);
    if (refreshed) {
      await fetchNotifications(isLoadMore: isLoadMore);
    } else {
      _handleAuthError('Session expired. Please log in again.');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
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
      final response = await apiService.deleteNotification(
        notificationId,
        token,
      );
      if (response['statusCode'] == 200 || response['statusCode'] == 204) {
        notifications.removeWhere((n) => n.id == notificationId);
        notifications.refresh();
        _showSnackBar(
          title: 'Success',
          message: 'Notification deleted successfully',
          isSuccess: true,
        );
      } else if (response['statusCode'] == 401) {
        final refreshToken = await storage.read(key: 'refresh');
        final refreshed = await authController.refreshAccessToken(
          refreshToken!,
        );
        if (refreshed) {
          final newToken = await authController.getAccessToken();
          if (newToken != null) {
            final retryResponse = await apiService.deleteNotification(
              notificationId,
              newToken,
            );
            if (retryResponse['statusCode'] == 200 ||
                retryResponse['statusCode'] == 204) {
              notifications.removeWhere((n) => n.id == notificationId);
              notifications.refresh();
              _showSnackBar(
                title: 'Success',
                message:
                    'Notification deleted successfully after token refresh',
                isSuccess: true,
              );
            } else {
              final errorMsg =
                  retryResponse['data']['error'] ??
                  'Failed to delete notification after token refresh';
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
            response['data']['error'] ?? 'Failed to delete notification';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error deleting notification: $e';
      debugPrint('Error: $e');
      _showSnackBar(
        title: 'Error',
        message: errorMessage.value,
        isSuccess: false,
      );
    }
  }

  Future<void> cancelScanning() async {
    isScanning1.value = false;
    try {
      mobileScannerController?.stop();
    } catch (e) {
      debugPrint('Failed to stop scanner: $e');
    }
    showCustomSnackBar(
      title: 'Scanning Cancelled',
      message: 'Image scanning has been cancelled.',
      backgroundColor: AppColor.orangeColor,
      isSuccess: false,
    );
  }

  Future<void> scanImageFromFile() async {
    debugPrint('Attempting to scan image from file');

    try {
      isLoading.value = true;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        debugPrint('Selected file: ${result.files.single.path}');
        final file = File(result.files.single.path!);
        selectedImage.value = Image.file(file, fit: BoxFit.contain);
        final token = await storage.read(key: 'access');
        if (token == null) {
          errorMessage.value = 'Authentication token not found. Please log in.';
          _showSnackBar(
            title: 'Error',
            message: errorMessage.value,
            isSuccess: false,
          );
          Get.toNamed(Routes.auth);
          return;
        }

        final response = await apiService.scanImage(file, token);
        debugPrint('API response status: ${response['statusCode']}');
        if (response['statusCode'] == 201) {
          qrResponse.value = response['data'];
          qrCode.value = response['data']['link'] ?? '';
          await incrementAdClickCount();
          Get.to(() => const QrCodeView());
        } else if (response['statusCode'] == 401) {
          final refreshToken = await storage.read(key: 'refresh');
          final refreshed = await authController.refreshAccessToken(
            refreshToken!,
          );
          if (refreshed) {
            final newToken = await authController.getAccessToken();
            if (newToken != null) {
              final retryResponse = await apiService.scanImage(file, newToken);
              if (retryResponse['statusCode'] == 201) {
                qrResponse.value = retryResponse['data'];
                qrCode.value = retryResponse['data']['link'] ?? '';
                await incrementAdClickCount();
                Get.to(() => const QrCodeView());
              } else {
                final errorMsg =
                    retryResponse['data']['error'] ??
                    'Failed to scan image after token refresh';
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
            errorMessage.value =
                'Failed to refresh token. Please log in again.';
            _showSnackBar(
              title: 'Error',
              message: errorMessage.value,
              isSuccess: false,
            );
            Get.toNamed(Routes.auth);
          }
        } else {
          debugPrint('No image selected');
          _showSnackBar(
            title: 'Error',
            message: response['data']['error'] ?? 'Failed to scan image',
            isSuccess: false,
          );
          selectedImage.value = Image.asset(
            ImageAssets.qrCode,
            fit: BoxFit.contain,
          );
        }
      } else {
        debugPrint('No image selected');
        _showSnackBar(
          title: 'Error',
          message: 'No image selected',
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error scanning image: $e');
      _showSnackBar(
        title: 'Error',
        message: 'Failed to scan image: $e',
        isSuccess: false,
      );
      selectedImage.value = Image.asset(
        ImageAssets.qrCode,
        fit: BoxFit.contain,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> scanImageFromFile1() async {
    debugPrint('Attempting to scan image from file1');

    try {
      isLoading(true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        debugPrint('Selected file: ${result.files.single.path}');
        final file = File(result.files.single.path!);
        selectedImage.value = Image.file(file, fit: BoxFit.contain);
        final response = await apiService.scanImage1(file);
        debugPrint('API response status: ${response['statusCode']}');
        if (response['statusCode'] == 200) {
          qrResponse.value = response['data'];
          qrCode.value = response['data']['link'] ?? '';
          await incrementAdClickCount();
          Get.to(() => const QrCodeView());
        } else {
          final error = response['data']['error'];
          debugPrint('errors: $error');
          showCustomSnackBar(
            title: 'Error',
            message: error ?? 'Failed to scan image',
            isSuccess: false,
          );
          selectedImage.value = Image.asset(
            ImageAssets.qrCode,
            fit: BoxFit.contain,
          );
        }
      } else {
        debugPrint('No image selected');
        showCustomSnackBar(
          title: 'Error',
          message: 'No image selected',
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error scanning image: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to scan image: $e',
        isSuccess: false,
      );
      selectedImage.value = Image.asset(
        ImageAssets.qrCode,
        fit: BoxFit.contain,
      );
    } finally {
      isLoading(false);
    }
  }

  var guides = <GuideModel>[].obs;
  var isGuide = false.obs;
  Future<void> fetchGuides() async {
    try {
      isGuide.value = true;
      errorMessage.value = '';
      final response = await apiService.getGuides();

      if (response['statusCode'] == 200) {
        final List<dynamic> data = response['data'];
        guides.value = data.map((json) => GuideModel.fromJson(json)).toList();

        Navigator.of(Get.context!).pop();
        Get.to(() => GuideView());
      } else {
        errorMessage.value =
            response['data']['error'] ?? 'Failed to fetch guides';
        _showSnackBar(
          title: 'Error',
          message: errorMessage.value,
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching guides: $e');
      errorMessage.value = 'Something went wrong';
    } finally {
      isGuide.value = false;
    }
  }
}
