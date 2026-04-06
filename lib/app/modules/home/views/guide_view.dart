import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:qr_code/app/modules/home/controllers/home_controller.dart';
import 'package:qr_code/res/app_url/app_url.dart';
import 'package:video_player/video_player.dart';

import '../../../../res/assets/image_assets.dart';
import '../../../../res/colors/app_color.dart';
import '../../../../widgets/custom_button.dart';
import '../../settings/controllers/settings_controller.dart';

class GuideView extends StatefulWidget {
  const GuideView({super.key});

  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> {
  final SettingsController controller = Get.find();
  final HomeController homeController = Get.find();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadAndPrepareVideo();
  }

  Future<void> _loadAndPrepareVideo() async {
    if (homeController.guides.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeController.fetchGuides();
      });
    }

    if (homeController.guides.isNotEmpty) {
      final guide = homeController.guides.first;
      final fullUrl = "${AppUrl.imageUrl}${guide.video}";

      _videoController = VideoPlayerController.networkUrl(Uri.parse(fullUrl));

      try {
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          aspectRatio: _videoController!.value.aspectRatio,
          autoPlay: false,
          looping: true,
          showControls: true,
        );
        setState(() {
          _isVideoInitialized = true;
        });
      } catch (e) {
        debugPrint("Video Initialization Error: $e");
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final textStyle = TextStyle(
        color: isDark ? AppColor.whiteColor : AppColor.textColor,
        fontFamily: 'Nunito Sans',
        fontWeight: FontWeight.w700,
      );

      return Scaffold(
        appBar: AppBar(
          title: Text('Guide', style: textStyle.copyWith(fontSize: 24.sp)),
          centerTitle: true,
          leading: _buildBackButton(isDark),
        ),
        body: homeController.isGuide.value
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(isDark, textStyle),
      );
    });
  }

  Widget _buildContent(bool isDark, TextStyle titleStyle) {
    final guideTitle = homeController.guides.isNotEmpty
        ? homeController.guides.first.title
        : 'TapQRLink Tutorial';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(guideTitle, style: titleStyle.copyWith(fontSize: 18.sp)),
          SizedBox(height: 20.h),

          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: const Color(0x7FD9D9D9),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: _isVideoInitialized && _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),
            ),
          ),

          SizedBox(height: 32.h),
          Text(
            'What you will learn ?',
            style: titleStyle.copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 18.h),

          _buildLearningRow('How to Scan a QR Code', isDark),
          _buildLearningRow('What to Do After Scanning', isDark),
          _buildLearningRow('Saving or Sharing Information', isDark),
          _buildLearningRow('Using the QR Code History', isDark),

          SizedBox(height: 30.h),
          Text('Quick Tip', style: titleStyle.copyWith(fontSize: 18.sp)),
          SizedBox(height: 8.h),
          Text(
            'Ensure the QR code is clear and not blurry. Adjust the distance or angle if needed.',
            style: titleStyle.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40.h),
          CustomButton(
            onPress: () async => Navigator.pop(Get.context!),
            title: 'Close',
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildLearningRow(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          SvgPicture.asset(ImageAssets.tic, height: 24.h, width: 24.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? AppColor.whiteColor : AppColor.textColor1,
                fontSize: 14.sp,
                fontFamily: 'Nunito Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return IconButton(
      icon: SvgPicture.asset(
        ImageAssets.backward,
        colorFilter: ColorFilter.mode(
          isDark ? AppColor.whiteColor : AppColor.textColor,
          BlendMode.srcIn,
        ),
      ),
      onPressed: () => Navigator.pop(Get.context!),
    );
  }
}
