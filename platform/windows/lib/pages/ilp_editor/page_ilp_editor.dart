import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:game/build_flavor.dart';
import 'package:game/data.dart';
import 'package:game/explorer/ilp_file.dart';
import 'package:game/global_progress_indicator_dialog.dart';
import 'package:game/info_table.dart';
import 'package:game/utils/textfield_number_formatter.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:steamworks/steamworks.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/steam_achievement.dart';
import '../../utils/steam_ex.dart';
import '../../utils/window_frame.dart';
import '../challenge/gallery_dialog.dart';
import '../explorer/steam/steam_file.dart';
import 'ilp_editor_controller.dart';
import 'ilp_editor_tips_dialog.dart';
import 'ilp_layer_editor_list_tile.dart';
import 'link_editor.dart';
import 'steam/steam_result_dialog.dart';

class PageILPEditor extends GetView<ILPEditorController> {
  final _formKey = GlobalKey<FormState>();
  final _layerKey = GlobalKey();

  PageILPEditor() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      ilpEditorTipsDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WindowFrame(
      title: UI.ilpEditor.tr,
      icons: [
        IconButton(
          tooltip: UI.help.tr,
          onPressed: () => ilpEditorTipsDialog(force: true),
          icon: Icon(
            Icons.help,
            color: Colors.pink,
          ),
        ),
      ],
      child: Row(
        children: [
          /// 文件信息
          Flexible(
            flex: 35,
            child: Form(
              key: _formKey,
              child: GetBuilder<ILPEditorController>(
                id: 'editor',
                builder: (controller) => Column(
                  children: [
                    Expanded(
                        child: ListView(
                      physics: ClampingScrollPhysics(),
                      children: [
                        _CoverListTile(),
                        ListTile(title: Text(UI.fileInfo.tr)),

                        /// name
                        ListTile(
                          title: TextFormField(
                            key: UniqueKey(),
                            decoration: InputDecoration(
                                labelText: '${UI.ilpName.tr}(*)'),
                            initialValue: controller.name,
                            onChanged: (val) => controller.name = val,
                            validator: (val) {
                              if (controller.name.isEmpty) {
                                return UI.contentCannotEmpty.tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        /// author
                        ListTile(
                          title: TextFormField(
                            key: UniqueKey(),
                            initialValue: controller.author,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                                labelText: '${UI.ilpAuthor.tr}(*)'),
                            onChanged: (val) => controller.author = val,
                            validator: (val) {
                              if (controller.author.isEmpty) {
                                return UI.contentCannotEmpty.tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        /// version
                        ListTile(
                          title: TextFormField(
                            key: UniqueKey(),
                            initialValue: controller.version.toString(),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: '${UI.ilpVersion.tr}(*)',
                              hintText: UI.ilpVersionTip.tr,
                            ),
                            onChanged: (val) =>
                                controller.version = int.tryParse(val) ?? 1,
                            validator: (val) {
                              if (controller.version < 0) {
                                return UI.ilpEditorVersionLimit.tr;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.phone,
                            inputFormatters: <TextInputFormatter>[
                              NumberFormatter,
                            ],
                          ),
                        ),

                        /// desc
                        ListTile(
                          title: TextFormField(
                            key: UniqueKey(),
                            initialValue: controller.desc,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            maxLines: 3,
                            minLines: 1,
                            decoration:
                                InputDecoration(labelText: UI.ilpDesc.tr),
                            onChanged: (val) => controller.desc = val,
                          ),
                        ),
                        EditFileTab(),
                        ListTile(
                          title: Wrap(
                            spacing: 10,
                            children: [
                              Text('${UI.link.tr}(${controller.links.length})'),
                              TextButton(
                                onPressed: () => LinkEditor.show(),
                                child: Icon(Icons.add),
                              )
                            ],
                          ),
                          trailing: Text(
                            UI.dragToSort.tr,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        ReorderableListView.builder(
                          physics: ClampingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: controller.links.length,
                          buildDefaultDragHandles: false,
                          onReorder: controller.reorderLink,
                          itemBuilder: (_, index) => _link(index),
                        ),
                      ],
                    )),
                    ListTile(
                      title: ElevatedButton(
                        child: Text(UI.saveToILPFile.tr),
                        onPressed: () {
                          if (controller.configs.isEmpty) {
                            showToast(UI.ilpEditorConfigFileEmpty.tr);
                            return;
                          }
                          if (_formKey.currentState!.validate()) {
                            controller.saveToLocalFile();
                          }
                        },
                      ),
                    ),
                    if (env.isSteam) Text(UI.or.tr),
                    if (env.isSteam)
                      ListTile(
                        title: ElevatedButton(
                          child: Text(UI.shareToSteam.tr),
                          onPressed: () async {
                            if (controller.configs.isEmpty) {
                              showToast(UI.ilpEditorConfigFileEmpty.tr);
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              final file = controller.file;

                              /// 确认更新文件
                              if (file is SteamFile) {
                                final sure = await Get.dialog(AlertDialog(
                                  title: Text(
                                      UI.ilpEditorConfirmUpdateSteamFile.tr),
                                  content: InfoTable(
                                    rows: [
                                      ('Steam id', file.id),
                                      (UI.name.tr, file.name),
                                      (UI.ilpVersion.tr, file.version),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text(UI.cancel.tr)),
                                    ElevatedButton(
                                      onPressed: () => Get.back(result: true),
                                      child: Text(UI.confirm.tr),
                                    )
                                  ],
                                ));
                                if (sure != true) return;
                              }

                              GlobalProgressIndicatorDialog.show(
                                  UI.steamUploading.tr);
                              final res = await controller.uploadToSteam();

                              /// hide indicator dialog
                              Get.back();

                              if (res == null) return;
                              if (res.result == EResult.eResultOK) {
                                SteamAchievement.contentCreator.achieved();
                              }
                              SteamResultDialog.show(result: res);
                            }
                          },
                        ),
                      ),
                    if (env.isSteam)
                      Text.rich(
                        TextSpan(text: UI.uploadAgreement.tr, children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                SteamClient.instance.openEulaUrl();
                              },
                              child: Text(
                                UI.agreementName.tr,
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ]),
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(width: 1),

          /// ILP配置文件列表
          Expanded(
            flex: 70,
            child: DropTarget(
              onDragDone: (detail) {
                if (detail.files.isEmpty) return;
                controller
                    .addConfigFiles(detail.files.map((e) => e.path).toList());
              },
              child: GetBuilder<ILPEditorController>(
                id: 'layers',
                builder: (controller) => Column(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Text(UI.ilpEditorConfigFileList.tr),
                          TextButton(
                            onPressed: controller.selectConfigFiles,
                            child: Icon(Icons.add),
                          ),
                          TextButton(
                            child: Icon(Icons.refresh),
                            onPressed: () {
                              for (var file in controller.configs) {
                                file.load();
                              }
                            },
                          ),
                        ],
                      ),
                      trailing: Text(
                        '${UI.dragToSort.tr}, ${UI.clickToModify.tr}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: controller.configs.isEmpty
                          ? _emptyLayers()
                          : ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              key: _layerKey,
                              shrinkWrap: true,
                              itemCount: controller.configs.length,
                              itemBuilder: (_, i) => _info(i),
                              onReorder: controller.reorderInfoAndLayer,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLayers() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.7,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(UI.ilpEditorEmptyTip1Title.tr),
                subtitle: Row(
                  children: [
                    TextButton(
                      onPressed: () => ilpEditorTipsDialog(force: true),
                      child: Text(
                        UI.ilpEditorEmptyTip1Btn.tr,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(UI.ilpEditorEmptyTip2Title.tr),
                subtitle: Text.rich(
                  TextSpan(
                    text: UI.ilpEditorEmptyTip2Content.tr,
                    children: [
                      WidgetSpan(
                        child: TextButton(
                          onPressed: controller.selectConfigFiles,
                          child: Text(
                            UI.ilpEditorEmptyTip2Btn.tr,
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (Data.locale.languageCode.startsWith('zh'))
                ListTile(
                  leading: Icon(FontAwesomeIcons.bilibili, color: Colors.blue),
                  title: Text('使用stable diffusion制作游戏内容的教程视频'),
                  onTap: () => launchUrlString(
                      'https://www.bilibili.com/video/BV1Qj411p76M'),
                ),
              ListTile(
                leading: Icon(FontAwesomeIcons.youtube, color: Colors.red),
                title: Text(
                    'Tutorial video for creating game content using stable diffusion(English)'),
                onTap: () => launchUrlString(
                    'https://www.youtube.com/watch?v=pI6nHgf974k'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(int index) {
    return ReorderableDragStartListener(
      key: Key(index.toString()),
      index: index,
      child: ILPEditorInfoListTile(file: controller.configs[index]),
    );
  }

  Widget _link(int index) {
    final link = controller.links[index];
    return ReorderableDragStartListener(
        key: Key(index.toString()),
        index: index,
        child: ListTile(
          title: Text(link.name),
          subtitle: Text(
            link.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => LinkEditor.show(link),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.link,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
                onTap: () => launchUrlString(link.url),
              ),
              SizedBox(width: 8),
              InkWell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
                onTap: () => controller.removeLink(link),
              ),
            ],
          ),
        ));
  }
}

class _CoverListTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ILPEditorController>(
      id: 'cover',
      builder: (controller) => ListTile(
        title: Text(UI.ilpCover.tr),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  controller.cover == null
                      ? SizedBox()
                      : Image.file(
                          File(controller.cover!),
                          width: 100,
                          height: 100,
                        ),
                  Positioned.fill(
                      child: InkWell(
                    onTap: controller.selectCoverFile,
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          UI.ilpChangeCover.tr,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ))
                ],
              ),
            ),
            if (controller.hasCover)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.cover!,
                        softWrap: true,
                      ),
                      TextButton(
                        child: Text(
                          UI.remove.tr,
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => controller.removeCover(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EditFileTab extends GetView<ILPEditorController> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Wrap(
                children: [
                  /// 本地文件
                  TextButton(
                    child: Text(UI.selectFileToUpdate.tr),
                    onPressed: () async {
                      const XTypeGroup typeGroup = XTypeGroup(
                        label: 'ILP file',
                        extensions: ['ilp'],
                      );
                      final XFile? file = await openFile(
                          acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                      if (file == null) return;
                      controller.file = ILPFile(File(file.path));
                    },
                  ),

                  /// 选择 Steam 文件
                  if (env.isSteam)
                    TextButton(
                      child: Text(UI.selectSteamFileToUpdate.tr),
                      onPressed: () async {
                        // final file = await SelectSteamFileDialog.show();
                        final files = await SteamGalleryDialog.show(
                            multipleSelect: false,
                            userId: SteamClient.instance.userId,
                            selected: {
                              if (controller.file != null &&
                                  controller.file is SteamFile)
                                (controller.file as SteamFile).id:
                                    controller.file as SteamFile,
                            });
                        if (files == null || files.isEmpty) return;
                        final file = files.values.first;
                        debugPrint('选择文件 ${files.length}');
                        if (file.steamIdOwner == SteamClient.instance.userId) {
                          controller.file = file;
                        } else {
                          showToast(UI.steamNotYourFile.tr);
                        }
                      },
                    ),
                ],
              ),
            ),
            if (controller.file != null)
              Obx(() {
                Widget? cover;
                if (controller.currentFileCover.value != null) {
                  if (controller.file is SteamFile) {
                    cover = Image.network(controller.currentFileCover.value);
                  } else if (controller.file is ILPFile) {
                    cover = Image.memory(controller.currentFileCover.value);
                  }
                }
                return ListTile(
                  leading: cover,
                  title: Text(controller.file!.name),
                  subtitle: controller.file is ILPFile
                      ? Text((controller.file as ILPFile).file.path)
                      : Text('ID: ${(controller.file as SteamFile).id}'),
                  trailing: Tooltip(
                    message: UI.cancel.tr,
                    child: InkWell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.close),
                      ),
                      onTap: () => controller.file = null,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
