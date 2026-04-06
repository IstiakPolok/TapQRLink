import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../settings/views/settings_view.dart';
import '../controllers/home_controller.dart';
import '../widget/curved_bottom_nav_bar.dart';
import 'history_view.dart';
import 'home_view.dart';
import 'notification_view.dart';

class Navbar extends StatelessWidget {
  final HomeController controller = Get.find();

  final svgIcons = [
    'assets/icons/home/scan.svg',
    'assets/icons/home/notify.svg',
    'assets/icons/home/history.svg',
    'assets/icons/home/settings.svg',
  ];

  final labels = ['Scan', 'Notification', 'History', 'Settings'];

  final pages = [HomeView(), NotificationView(), HistoryView(), SettingsView()];

  Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => pages[controller.selectedIndex.value]),
      bottomNavigationBar: SafeArea(
        child: Obx(
          () => CurvedBottomNavBar(
            selectedIndex: controller.selectedIndex.value,
            onItemTapped: controller.changePage,
            svgIcons: svgIcons,
            labels: labels,
          ),
        ),
      ),
    );
  }
}
