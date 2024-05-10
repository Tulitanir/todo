import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await openDatabase(
      join(await getDatabasesPath(), 'todo.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, priority INTEGER, deadline INTEGER, finishdate INTEGER)',
        );
      },
      version: 1,
    );

    return _database!;
  }
}