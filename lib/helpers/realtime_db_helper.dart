import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBHelper {
  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://game-76a82-default-rtdb.europe-west1.firebasedatabase.app',
  );

  /// set or create data
  static Future<void> setData(String path, dynamic value) async {
    try {
      await _db.ref(path).set(value);
      if (kDebugMode) print('Data set: $path');
    } catch (e) {
      if (kDebugMode) print('Error setting data: $e');
      rethrow;
    }
  }

  /// get data once
  static Future<DataSnapshot> getData(String path) async {
    try {
      return await _db.ref(path).get();
    } catch (e) {
      if (kDebugMode) print('Error getting data: $e');
      rethrow;
    }
  }

  /// update data
  static Future<void> updateData(String path, dynamic updates) async {
    try {
      await _db.ref(path).update(updates);
      if (kDebugMode) print('Data updated at $path => $updates');
    } catch (e) {
      if (kDebugMode) print('Error updating data: $e');
      rethrow;
    }
  }

  /// remove data
  static Future<void> removeData(String path) async {
    try {
      await _db.ref(path).remove();
      if (kDebugMode) print('Data removed: $path');
    } catch (e) {
      if (kDebugMode) print('Error removing data: $e');
      rethrow;
    }
  }

  /// get a DatabaseReference
  static DatabaseReference ref(String path) {
    return _db.ref(path);
  }

  /// push node
  static DatabaseReference push(String path) {
    return _db.ref(path).push();
  }
}
