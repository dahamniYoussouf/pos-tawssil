import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void initDatabase() {
  // Initialize SQLite for Web using sql.js (WebAssembly)
  databaseFactory = databaseFactoryFfiWeb;
}
