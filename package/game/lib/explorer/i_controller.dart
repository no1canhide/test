import 'file.dart';

abstract class IExplorerController {
  List<(String, String)> get folders;

  List<ExplorerFile> get files;

  String get currentPath;

  int get currentFolder;

  openFolder(int index);

  reload();
}
