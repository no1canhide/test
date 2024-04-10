import 'package:flutter/material.dart';
import 'package:game/about_card.dart';
import 'package:get/get.dart';
import 'package:ui/ui.dart';

import '../utils/version.dart';

class PageAbout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final buildNumber =
        packageInfo.buildNumber.isEmpty ? '' : '_${packageInfo.buildNumber}';
    return Scaffold(
      appBar: AppBar(
        title: Text(UI.about.tr),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: AboutCard(
              version: '${packageInfo.version}$buildNumber',
            ),
          ),
        ),
      ),
    );
  }
}
