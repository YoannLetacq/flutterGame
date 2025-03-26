import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Encapsules les opertions de basique de firestore
class FirestoreHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Set ou Create un document
  static Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).doc(docId).set(data);
      if (kDebugMode) {
        print('Document set: $collection/$docId');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error setting document: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Get un document
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final docSnapshot = await _db.collection(collection).doc(docId).get();
      if (kDebugMode) {
        print('Document retrieved: $collection/$docId');
      }
      return docSnapshot;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error getting document: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// get collection
  static Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collection,
  }) async {
    try {
      final snapshot = await _db.collection(collection).get();
      if (kDebugMode) {
        print('Collection retrieved: $collection');
      }
      return snapshot;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error getting collection: $e');
        print(stack);
      }
      rethrow;
    }
  }


  /// Update un document
  static Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
      if (kDebugMode) {
        print('Document updated: $collection/$docId');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error updating document: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Delete un document
  static Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _db.collection(collection).doc(docId).delete();
      if (kDebugMode) {
        print('Document deleted: $collection/$docId');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error deleting document: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// add un document
  static Future<DocumentReference<Map<String, dynamic>>> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _db.collection(collection).add(data);
      if (kDebugMode) {
        print('Document added: $collection/${docRef.id}');
      }
      return docRef;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error adding document: $e');
        print(stack);
      }
      rethrow;
    }
  }


}