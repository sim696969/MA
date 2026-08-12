import 'package:cloud_firestore/cloud_firestore.dart';

/// DatabaseService handles CRUD operations with Cloud Firestore.
class DatabaseService {
  final FirebaseFirestore _db;

  DatabaseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Generic / Helper CRUD Methods
  // ---------------------------------------------------------------------------

  /// Create or add a new document to a collection with auto-generated ID.
  Future<DocumentReference<Map<String, dynamic>>> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final timestampData = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return await _db.collection(collectionPath).add(timestampData);
  }

  /// Create or set a document with a specific ID.
  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final timestampData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db
        .collection(collectionPath)
        .doc(docId)
        .set(timestampData, SetOptions(merge: merge));
  }

  /// Read a single document by ID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    return await _db.collection(collectionPath).doc(docId).get();
  }

  /// Read all documents in a collection as a stream.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Read all documents in a collection once.
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return await query.get();
  }

  /// Update specific fields of an existing document.
  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final updateData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db.collection(collectionPath).doc(docId).update(updateData);
  }

  /// Delete a document by ID.
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    await _db.collection(collectionPath).doc(docId).delete();
  }

  // ---------------------------------------------------------------------------
  // Feature-Specific Helpers (Invitations, Layouts, etc.)
  // ---------------------------------------------------------------------------

  /// Save or update an invitation.
  Future<void> saveInvitation({
    String? invitationId,
    required String coupleNames,
    required String date,
    required String location,
    required String templateId,
  }) async {
    final data = {
      'coupleNames': coupleNames,
      'date': date,
      'location': location,
      'templateId': templateId,
    };

    if (invitationId != null && invitationId.isNotEmpty) {
      await setDocument(collectionPath: 'invitations', docId: invitationId, data: data);
    } else {
      await addDocument(collectionPath: 'invitations', data: data);
    }
  }

  /// Stream invitations for a user/wedding.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamInvitations() {
    return streamCollection(
      collectionPath: 'invitations',
      queryBuilder: (q) => q.orderBy('updatedAt', descending: true),
    );
  }

  /// Save layout planner items.
  Future<void> saveLayoutItems({
    required String layoutId,
    required List<Map<String, dynamic>> items,
  }) async {
    await setDocument(
      collectionPath: 'layouts',
      docId: layoutId,
      data: {
        'items': items,
      },
    );
  }

  /// Stream layout details.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLayout(String layoutId) {
    return _db.collection('layouts').doc(layoutId).snapshots();
  }
}
