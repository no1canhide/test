import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oktoast/oktoast.dart';
import 'package:ui/ui.dart';

import '../../extension_duration.dart';
import '../level_controller.dart';
import '../puzzle/level_puzzle.dart';
import '../resources.dart';
import '../stroke_shadow.dart';

class TipToolWidget<T extends LevelController> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: UI.gameBarTip.tr,
      child: GetBuilder<T>(
          id: 'tip',
          builder: (controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (controller.nextHintTime.inMilliseconds > 0)
                  StrokeShadow.text(
                    controller.nextHintTime.toSemanticString(),
                    style: GoogleFonts.lilitaOne(
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                    stroke: Stroke(
                      width: 2,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ),
                FloatingActionButton(
                  onPressed: () {
                    if (controller.showHint(controller.currentLevel)) {
                      final level = controller.currentLevel!;
                      showToast(level is LevelPuzzle
                          ? UI.puzzleHint.tr
                          : UI.findDifferencesHint.tr);
                    }
                  },
                  child: StrokeShadow.path(
                    Resources.iconFocus,
                    color: controller.nextHintTime.inMilliseconds > 0
                        ? Colors.grey
                        : Theme.of(context).hintColor,
                  ),
                ),
              ],
            );
          }),
    );
  }
}

class DurationPainter extends CustomPainter {
  final Duration duration;

  DurationPainter(this.duration);

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: formatDuration(duration),
        style: GoogleFonts.lilitaOne(
          fontSize: 16,
          letterSpacing: 1.5,
          color: Colors.red,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    double x = (size.width - textPainter.width) / 2;
    double y = (size.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(DurationPainter oldDelegate) {
    return oldDelegate.duration != duration;
  }
}

String formatDuration(Duration duration) {
  int minutes = duration.inMinutes;
  int seconds = duration.inSeconds.remainder(60);
  int milliseconds = duration.inMilliseconds.remainder(1000);

  return '$minutes:${seconds.toString().padLeft(2, '0')}:${milliseconds.toString().padLeft(3, '0')}';
}
