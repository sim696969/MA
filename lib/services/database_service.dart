import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guest_invitation_model.dart';
import '../models/catering_order_model.dart';

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
  // Feature-Specific Helpers (Invitations, Guests, Catering, Layouts, etc.)
  // ---------------------------------------------------------------------------

  String _guestsCollectionPath(String projectId) =>
      'user_wedding_projects/$projectId/guests';

  String _cateringOrdersCollectionPath(String projectId) =>
      'user_wedding_projects/$projectId/catering_orders';

  /// Save a completed catering order in Firestore.
  Future<void> saveCateringOrder({
    required String projectId,
    required CateringOrderModel order,
  }) async {
    final path = _cateringOrdersCollectionPath(projectId);
    final docRef = order.orderId.isNotEmpty
        ? _db.collection(path).doc(order.orderId)
        : _db.collection(path).doc();

    final data = {
      ...order.toMap(),
      'orderId': docRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));
  }

  /// Get the most recent catering order for a project if one exists.
  Future<CateringOrderModel?> getLatestCateringOrder({
    required String projectId,
  }) async {
    final path = _cateringOrdersCollectionPath(projectId);
    final snapshot = await _db
        .collection(path)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return CateringOrderModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  /// Stream all catering orders for a wedding project.
  Stream<List<CateringOrderModel>> streamCateringOrders({
    required String projectId,
  }) {
    final path = _cateringOrdersCollectionPath(projectId);
    return _db
        .collection(path)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CateringOrderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Save or update a guest invitation in Firestore.
  Future<void> saveGuestInvitation({
    required String projectId,
    required GuestInvitationModel guest,
  }) async {
    final path = _guestsCollectionPath(projectId);
    final docRef = guest.id.isNotEmpty
        ? _db.collection(path).doc(guest.id)
        : _db.collection(path).doc();

    final data = {
      ...guest.toMap(),
      'id': docRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));
  }

  /// Stream all guests/invitations for a wedding project.
  Stream<List<GuestInvitationModel>> streamGuestInvitations({
    required String projectId,
  }) {
    final path = _guestsCollectionPath(projectId);
    return _db
        .collection(path)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GuestInvitationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetch all guests/invitations once for a wedding project.
  Future<List<GuestInvitationModel>> getGuestInvitations({
    required String projectId,
  }) async {
    final path = _guestsCollectionPath(projectId);
    final snapshot = await _db
        .collection(path)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => GuestInvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Delete a guest invitation.
  Future<void> deleteGuestInvitation({
    required String projectId,
    required String guestId,
  }) async {
    final path = _guestsCollectionPath(projectId);
    await _db.collection(path).doc(guestId).delete();
  }

  /// Update guest invitation status (e.g., 'draft' -> 'sent').
  Future<void> updateGuestInvitationStatus({
    required String projectId,
    required String guestId,
    required String status,
  }) async {
    final path = _guestsCollectionPath(projectId);
    await _db.collection(path).doc(guestId).update({
      'status': status,
      'sentAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Batch update all draft guests to 'sent' status.
  Future<int> sendAllInvitationsBatch({
    required String projectId,
    required List<GuestInvitationModel> guests,
  }) async {
    final path = _guestsCollectionPath(projectId);
    final WriteBatch batch = _db.batch();
    int count = 0;

    for (final guest in guests) {
      final docRef = _db.collection(path).doc(guest.id);
      batch.set(
        docRef,
        {
          ...guest.toMap(),
          'id': guest.id,
          'status': 'sent',
          'sentAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }
    return count;
  }

  /// Save or update a generic invitation.
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
