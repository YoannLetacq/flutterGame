import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBHelper {
  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://game-76a82-default-rtdb.europe-west1.firebasedatabase.app',
  );

  /// Convert any value to Map if possible
  static Map<String, dynamic> _normalize(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value != null && value.toJson is Function) {
      return value.toJson() as Map<String, dynamic>;
    } else {
      throw ArgumentError('Value must be a Map<String, dynamic> or have a toJson() method');
    }
  }

  /// set or create data
  static Future<void> setData(String path, dynamic value) async {
    try {
      final data = _normalize(value);
      await _db.ref(path).set(data);
      if (kDebugMode) {
        print('Data set: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting data: $e');
      }
      rethrow;
    }
  }

  /// get data once
  static Future<DataSnapshot> getData(String path) async {
    try {
      return await _db.ref(path).get();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting data: $e');
      }
      rethrow;
    }
  }

  /// update data
  static Future<void> updateData(String path, dynamic updates) async {
    try {
      final data = _normalize(updates);
      await _db.ref(path).update(data);
      if (kDebugMode) {
        print('Data updated at $path => $data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating data: $e');
      }
      rethrow;
    }
  }

  /// remove data
  static Future<void> removeData(String path) async {
    try {
      await _db.ref(path).remove();
      if (kDebugMode) {
        print('Data removed: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing data: $e');
      }
      rethrow;
    }
  }

  /// run transaction
  static Future<TransactionResult> runTransaction(String path, TransactionHandler transactionHandler) async {
    try {
      return await _db.ref(path).runTransaction(transactionHandler);
    } catch (e) {
      if (kDebugMode) {
        print('Error running transaction: $e');
      }
      rethrow;
    }
  }

  /// get a reference
  static Future<DatabaseReference> ref(String path) async {
    try {
      return _db.ref(path);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting reference: $e');
      }
      rethrow;
    }
  }

  /// push data
  static Future<DatabaseReference> push(String path) async {
    try {
      return _db.ref(path).push();
    } catch (e) {
      if (kDebugMode) {
        print('Error pushing data: $e');
      }
      rethrow;
    }
  }
}
