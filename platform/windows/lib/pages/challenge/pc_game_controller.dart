import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:game/core.dart';
import 'package:game/data.dart';
import 'package:game/explorer/file.dart';
import 'package:game/explorer/ilp_file.dart';
import 'package:game/game/game_mode.dart';
import 'package:game/game/level_controller.dart';
import 'package:game/game/mouse_controller.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:steamworks/steamworks.dart';

import '../../utils/steam_achievement.dart';
import '../../utils/steam_ex.dart';
import '../explorer/steam/steam_file.dart';

class PCGameController extends LevelController with MouseController {
  PCGameController({required super.files, required super.mode, super.ilpIndex});

  @override
  Offset onScalePosition(Offset position) {
    // -2 是纵向分割线的宽度
    final half = (Get.width - 2) / 2;
    return Offset(
      position.dx < half ? position.dx : position.dx - half,
      position.dy,
    );
  }

  Timer? _downloadTimer;

  Future<File> _downloadSteamFile(SteamSimpleFile file) async {
    SteamClient.instance.steamUgc.suspendDownloads(false);
    final download = SteamClient.instance.downloadUGCItem(
      file.id,
      highPriority: true,
    );
    final completer = Completer<String>();
    _downloadTimer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      await file.updateDownloadBytes();
      downloadedBytes = file.downloadedBytes;
      totalBytes = file.totalBytes;
      update(['ui']);
    });
    await download;
    _downloadTimer?.cancel();
    using((arena) async {
      final size = arena<UnsignedLongLong>();
      final folder = arena<Uint8>(1000).cast<Utf8>();
      final timeStamp = arena<UnsignedInt>();
      final installed = SteamClient.instance.steamUgc.getItemInstallInfo(
        file.id,
        size,
        folder,
        1000,
        timeStamp,
      );
      completer.complete(folder.toDartString());
    });
    return File(path.join(await completer.future, 'main.ilp'));
  }

  @override
  Future<void> loadFile(ExplorerFile file, math.Random random) async {
    if (file is SteamSimpleFile) {
      file = ILPFile(await _downloadSteamFile(file));
    }
    return super.loadFile(file, random);
  }

  @override
  void exit() {
    /// 让steam停止下载创意工坊文件
    if (env.isSteam) {
      SteamClient.instance.steamUgc.suspendDownloads(true);
    }
    Get.back(id: 1);
  }

  @override
  void onCompleted() {
    print('是否测试模式: $isTest');
    print('level controller onCompleted, id层数量${Data.layersId.length}');
    super.onCompleted();
    print('pc game controller onCompleted, id层数量${Data.layersId.length}');
    if (isTest) return;
    _checkAchievements();
  }

  void _checkAchievements() async {
    if (!isCompleted) return;

    if (mode == GameMode.challenge) {
      /// 达成 挑战者 成就
      SteamAchievement.challenger.achieved();
    }

    /// 更新图层数量统计
    SteamAchievement.updateInt('unlocked_layers', Data.layersId.length);

    /// 检查是否满足 强迫症玩家 成就
    for (var file in files) {
      await file.load(force: true);
      // print('${file.runtimeType.toString()} 解锁进度 ${file.unlock}');
      if (file.unlock >= 1.0) {
        SteamAchievement.ocdGamer.achieved();
        break;
      }
    }
  }
}
