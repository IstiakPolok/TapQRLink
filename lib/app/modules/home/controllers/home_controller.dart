import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  var isBannerLoaded = false.obs;

  final String bannerId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  final String interstitialId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  void loadBanner() {
    bannerAd?.dispose();
    isBannerLoaded.value = false;
    bannerAd = BannerAd(
      adUnitId: bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerLoaded.value = true;
        },
        onAdFailedToLoad: (ad, err) {
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
        onAdLoaded: (ad) => interstitialAd = ad,
        onAdFailedToLoad: (err) => interstitialAd = null,
      ),
    );
  }

  void showInterstitial() {
    if (interstitialAd != null) {
      interstitialAd!.show();
      loadInterstitial();
    } else {
      debugPrint("Interstitial Ad not ready yet");
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
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else {
      Get.snackbar(
        'Permission Denied',
        'Camera access is required to scan QR codes',
      );
      return false;
    }
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
      isScanning.value = true;
      isScanning1.value = true;
      if (mobileScannerController == null) {
        initializeScanner();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await mobileScannerController!.start();
        updateCameraZoom();
      });
    } catch (e) {
      isScanning.value = false;
      isScanning1.value = false;
      Get.snackbar('Error', 'Failed to start scanner: $e');
      initializeScanner();
    }
  }

  void stopScanning() {
    try {
      mobileScannerController?.stop();
    } catch (e) {
      Get.snackbar('Error', 'Failed to stop scanner: $e');
    } finally {
      isScanning.value = false;
      isScanning1.value = false;
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Success', 'Link copied to clipboard');
  }

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    loadHistory();
    loadBanner();
    loadInterstitial();
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
      if (!isLoadMore) {
        isLoading.value = true;
        historyItems.clear();
        nextPageUrl.value = null;
      } else {
        if (nextPageUrl.value == null) return;
        isLoading.value = true;
      }

      final token = await storage.read(key: 'access');

      final String targetUrl = isLoadMore
          ? nextPageUrl.value!
          : AppUrl.historyUrl;

      debugPrint("🚀 Requesting URL: $targetUrl");

      final response = await apiService.getHistory(token!, url: targetUrl);

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
      Get.snackbar(
        'Error',
        'Could not open link',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
      Get.snackbar('Error', 'Failed to stop scanner: $e');
    }
    Get.snackbar('Scanning Cancelled', 'Image scanning has been cancelled.');
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
          Get.snackbar('Error', error ?? 'Failed to scan image');
          selectedImage.value = Image.asset(
            ImageAssets.qrCode,
            fit: BoxFit.contain,
          );
        }
      } else {
        debugPrint('No image selected');
        Get.snackbar('Error', 'No image selected');
      }
    } catch (e) {
      debugPrint('Error scanning image: $e');
      Get.snackbar('Error', 'Failed to scan image: $e');
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
