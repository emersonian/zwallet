import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:warp_api/warp_api.dart';

import '../main.dart';

class LWInstance {
  String name;
  String url;

  LWInstance(this.name, this.url);
}

abstract class CoinBase {
  String get name;
  int get coin;
  String get app;
  String get symbol;
  String get currency;
  String get ticker;
  int get coinIndex;
  String get explorerUrl;
  AssetImage get image;
  String get dbName;
  late String dbDir;
  late String dbFullPath;
  late Database db;
  List<LWInstance> get lwd;
  bool get supportsUA;
  bool get supportsMultisig;
  List<double> get weights;

  void init(String dbDirPath) {
    dbDir = dbDirPath;
    dbFullPath = _getFullPath(dbDir);
  }

  bool exists() => File(dbFullPath).existsSync();

  Future<void> open(bool wal) async {
    print("Opening DB ${dbFullPath}");
    // schema handled in backend
    db = await openDatabase(dbFullPath, onConfigure: (db) async {
      if (wal)
        await db.rawQuery("PRAGMA journal_mode=WAL");
    });
  }

  Future<void> close() async {
    await db.close();
  }

  Future<bool> tryImport(PlatformFile file) async {
    if (file.name == dbName) {
      final dest = p.join(settings.tempDir, dbName);
      await File(file.path!).copy(dest); // save to temporary directory
      return true;
    }
    return false;
  }

  Future<void> importFromTemp() async {
    final src = File(p.join(settings.tempDir, dbName));
    print("Import from ${src.path}");
    if (await src.exists()) {
      print("copied to ${dbFullPath}");
      await delete();
      await src.copy(dbFullPath);
      await src.delete();
    }
  }

  Future<void> export(BuildContext context, String dbPath) async {
    final path = _getFullPath(dbPath);
    db = await openDatabase(path, onConfigure: (db) async {
      await db.rawQuery("PRAGMA journal_mode=off");
    });
    await db.close();
    await exportFile(context, path, dbName);
  }

  Future<void> delete() async {
    try {
      await File(p.join(dbDir, dbName)).delete();
      await File(p.join(dbDir, "${dbName}-shm")).delete();
      await File(p.join(dbDir, "${dbName}-wal")).delete();
    }
    catch (e) {} // ignore failure
  }

  String _getFullPath(String dbPath) {
    final path = p.join(dbPath, dbName);
    return path;
  }
}

Future<void> createSchema(Database db, int version) async {
  final script = await rootBundle.loadString("assets/create_db.sql");
  final statements = script.split(";");
  for (var s in statements) {
    if (s.isNotEmpty) {
      final sql = s.trim();
      print(sql);
      db.execute(sql);
    }
  }
}

