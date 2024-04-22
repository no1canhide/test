import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ui/ui.dart';
import 'package:window_manager/window_manager.dart';

late PackageInfo packageInfo;

updateWindowTitle() async {
  // print('设置窗口标题 ${UI.findUp.tr} v${packageInfo.version}');
  windowManager.setTitle('${UI.findUp.tr} v${packageInfo.version}');
}
