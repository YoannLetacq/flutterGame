import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDBHelper {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// set ou create data
  static Future<void> setData(String path, dynamic value) async {
   try {
     await _db.ref(path).set(value);
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
  static Future<void> updateData(String  path, Map<String, dynamic> updates) async {
    try {
      await _db.ref(path).update(updates);
      if (kDebugMode) {
        print('Data updated at $path => $updates');
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
}