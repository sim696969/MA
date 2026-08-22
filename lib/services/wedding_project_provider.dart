import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wedding_project_model.dart';
import 'auth_session_service.dart';
import 'database_service.dart';

const String _kWeddingProjectKey = 'wedify_active_wedding_project';

final weddingProjectProvider =
    StateNotifierProvider<WeddingProjectNotifier, WeddingProject>((ref) {
      final authState = ref.watch(authStateProvider);
      return WeddingProjectNotifier(userEmail: authState.email);
    });

String _generateFreshProjectId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final rand = Random().nextInt(9999).toString().padLeft(4, '0');
  return 'proj_${now}_$rand';
}

enum PaymentModificationType { none, balanceDue, refundDue, unchanged }

class PaymentModificationResult {
  final PaymentModificationType type;
  final double amount;

  const PaymentModificationResult(this.type, [this.amount = 0.0]);
}

class WeddingProjectNotifier extends StateNotifier<WeddingProject> {
  final String? userEmail;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  WeddingProjectNotifier({this.userEmail})
    : super(WeddingProject(id: _generateFreshProjectId())) {
    _loadProject();
  }

  String _sanitizeDocId(String email) {
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// Public getter for the Firestore document ID that hosts this project's
  /// metadata AND subcollections (guests, catering_orders, etc.).
  ///
  /// Equivalent to the private `_currentUserId`. Feature screens SHOULD use
  /// this getter when calling `DatabaseService` subcollection CRUD methods
  /// like `saveGuestInvitation(projectId: ...)` or `saveCateringOrder(projectId: ...)`.
  ///
  /// DO NOT confuse this with `WeddingProject.id`, which is a session-scoped
  /// unique identifier used for top-level standalone collections like `layouts/{id}`.
  String get firestoreProjectDocId => _currentUserId;

  String get _currentUserId {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      return firebaseUser.uid;
    }
    if (userEmail != null && userEmail!.isNotEmpty) {
      return _sanitizeDocId(userEmail!);
    }
    return 'default_user';
  }

  Future<void> _loadProject() async {
    // 1. Load from local cache first for instant UI response
    await _loadFromLocalPreferences();

    // 2. Sync from Cloud Firestore if user is authenticated
    final userId = _currentUserId;
    if (userId != 'default_user') {
      try {
        final doc = await _firestore
            .collection('user_wedding_projects')
            .doc(userId)
            .get();
        if (doc.exists && doc.data() != null) {
          final firestoreProject = WeddingProject.fromMap(doc.data()!);
          state = firestoreProject;
          await _saveToLocalPreferences();
        } else if (state.isInitialized) {
          // If Firestore is empty but local has data, upload local data to Firestore
          await _saveToFirestore();
        }
      } catch (e) {
        // Fallback to local storage if network is offline
      }
    }
  }

  Future<void> _loadFromLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(
        '${_kWeddingProjectKey}_$_currentUserId',
      );
      if (jsonStr != null && jsonStr.isNotEmpty) {
        state = WeddingProject.fromJson(jsonStr);
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _saveToLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_kWeddingProjectKey}_$_currentUserId',
        state.toJson(),
      );
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _saveToFirestore() async {
    final userId = _currentUserId;
    if (userId == 'default_user') return;

    try {
      await _firestore.collection('user_wedding_projects').doc(userId).set({
        ...state.toMap(),
        'userId': userId,
        'userEmail': userEmail ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle cloud save error
    }
  }

  Future<void> _autoSave() async {
    await _saveToLocalPreferences();
    await _saveToFirestore();
  }

  Future<PaymentModificationResult> _saveServiceUpdate(
    WeddingProject previousState,
  ) async {
    if (!previousState.isPaid) {
      await _autoSave();
      return const PaymentModificationResult(PaymentModificationType.none);
    }

    final difference = state.totalPayable - previousState.amountPaid;
    if (difference > 0.009) {
      state = state.copyWith(
        paymentStatus: 'pending',
        pendingRefundAmount: 0.0,
        paymentNotice:
            'Payment Incomplete: You updated your booking! Please complete the remaining balance payment to confirm your changes.',
      );
      await _autoSave();
      return PaymentModificationResult(
        PaymentModificationType.balanceDue,
        difference,
      );
    }

    if (difference < -0.009) {
      final refundAmount = -difference;
      state = state.copyWith(
        paymentStatus: 'paid',
        pendingRefundAmount: refundAmount,
        paymentNotice:
            'Booking Updated - Refund Notice: Our team will contact you by email about your refund.',
      );
      await _autoSave();
      final projectId = _currentUserId;
      if (projectId != 'default_user') {
        await _firestore.collection('pendingRefunds').doc(projectId).set({
          'projectId': projectId,
          'userEmail': userEmail ?? '',
          'refundAmount': refundAmount,
          'previouslyPaid': previousState.amountPaid,
          'newTotal': state.totalPayable,
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return PaymentModificationResult(
        PaymentModificationType.refundDue,
        refundAmount,
      );
    }

    state = state.copyWith(
      paymentStatus: 'paid',
      pendingRefundAmount: 0.0,
      paymentNotice: 'Booking details updated successfully.',
    );
    await _autoSave();
    return const PaymentModificationResult(PaymentModificationType.unchanged);
  }

  Future<void> setDateTime(DateTime date, String time) async {
    state = state.copyWith(weddingDate: date, weddingTime: time);
    await _autoSave();
  }

  Future<PaymentModificationResult> updateVenue({
    required String venueName,
    required double fee,
    String? venueId,
    String? venueAddress,
    bool isCompleted = true,
  }) async {
    final previousState = state;
    state = state.copyWith(
      selectedVenueName: venueName,
      selectedVenueId: venueId,
      selectedVenueAddress: venueAddress,
      venueFee: fee,
      isVenueCompleted: isCompleted,
    );
    return _saveServiceUpdate(previousState);
  }

  /// Saves a venue against the project identity active at the moment of booking.
  ///
  /// The Firestore document ID is derived from the current Auth session here,
  /// rather than from a value captured when the screen was opened.
  Future<PaymentModificationResult> bookVenue({
    required String venueName,
    required double fee,
    String? venueId,
    String? venueAddress,
  }) async {
    final previousState = state;
    state = state.copyWith(
      selectedVenueName: venueName,
      selectedVenueId: venueId,
      selectedVenueAddress: venueAddress,
      venueFee: fee,
      isVenueCompleted: true,
    );
    await _saveToLocalPreferences();

    final projectId = _currentUserId;
    if (projectId == 'default_user') {
      state = previousState;
      await _saveToLocalPreferences();
      throw StateError('Please sign in before booking a venue.');
    }

    try {
      return await _saveServiceUpdate(previousState);
    } catch (e) {
      state = previousState;
      await _saveToLocalPreferences();
      rethrow;
    }
  }

  Future<PaymentModificationResult> updatePlannerLayout({
    required String layoutSummary,
    required double fee,
    bool isCompleted = true,
  }) async {
    final previousState = state;
    state = state.copyWith(
      plannerLayoutSummary: layoutSummary,
      plannerFee: fee,
      isPlannerCompleted: isCompleted,
    );
    return _saveServiceUpdate(previousState);
  }

  Future<PaymentModificationResult> updateInvitation({
    required String invitationName,
    required double fee,
    bool isCompleted = true,
  }) async {
    final previousState = state;
    state = state.copyWith(
      selectedInvitationName: invitationName,
      invitationFee: fee,
      isInvitationCompleted: isCompleted,
      invitationOptedOut: false,
    );
    return _saveServiceUpdate(previousState);
  }

  Future<PaymentModificationResult> optOutOfInvitation() async {
    final previousState = state;
    state = state.copyWith(
      invitationOptedOut: true,
      isInvitationCompleted: false,
      invitationFee: 0.0,
      selectedInvitationName: "Physical Invitations (Self-Managed)",
    );
    return _saveServiceUpdate(previousState);
  }

  Future<PaymentModificationResult> undoInvitationOptOut() async {
    final previousState = state;
    state = state.copyWith(
      invitationOptedOut: false,
      selectedInvitationName: null,
    );
    return _saveServiceUpdate(previousState);
  }

  Future<PaymentModificationResult> updateCatering({
    required String cateringPackage,
    required double fee,
    bool isCompleted = true,
  }) async {
    final previousState = state;
    state = state.copyWith(
      selectedCateringPackage: cateringPackage,
      cateringFee: fee,
      isCateringCompleted: isCompleted,
    );
    return _saveServiceUpdate(previousState);
  }

  /// Mark project as paid and sync to Firestore
  Future<void> markAsPaid({
    required String transactionId,
    required double amountPaid,
    DateTime? paymentDate,
  }) async {
    state = state.copyWith(
      paymentStatus: 'paid',
      transactionId: transactionId,
      amountPaid: amountPaid,
      paymentDate: paymentDate ?? DateTime.now(),
      pendingRefundAmount: 0.0,
      paymentNotice: '',
    );
    await _autoSave();
  }

  /// Reset ONLY the project metadata (venue/planner/invitation/catering flags & fees).
  /// Preserves subcollections. Use [fullResetAllBookingData()] instead for Cancel Wedding.
  Future<void> resetProject() async {
    final userId = _currentUserId;
    state = WeddingProject(id: _generateFreshProjectId());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_kWeddingProjectKey}_$userId');

    if (userId != 'default_user') {
      try {
        await _firestore
            .collection('user_wedding_projects')
            .doc(userId)
            .delete();
      } catch (e) {
        // Handle deletion error
      }
    }
  }

  /// COMPLETE BOOKING DATA WIPE — call this when user clicks "Cancel Wedding Project".
  ///
  /// Deletes:
  ///  - Project metadata doc in Firestore
  ///  - ALL guests/invitations subcollection
  ///  - ALL catering_orders subcollection
  ///  - Linked standalone layout document
  ///  - Linked standalone invitation docs
  ///  - Local SharedPreferences cache
  ///  - In-memory Riverpod state
  ///
  /// After the purge, generates a brand-new unique project ID so the next
  /// booking session reads/writes to a fresh Firestore document scope and
  /// feature screens no longer think they're on a "canceled" project.
  Future<void> fullResetAllBookingData() async {
    final userId = _currentUserId;

    // 1. First, delete all Firestore SUBCOLLECTIONS linked to the project
    //    (guests, catering orders, layouts, invitations)
    try {
      await _dbService.deleteAllProjectSubcollections(projectId: userId);
    } catch (_) {}

    // 2. Delete the main project metadata document itself
    if (userId != 'default_user') {
      try {
        await _firestore
            .collection('user_wedding_projects')
            .doc(userId)
            .delete();
      } catch (_) {}
    }

    // 3. Wipe local SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.remove('${_kWeddingProjectKey}_$userId');
    } catch (_) {}

    // 4. Finally, reset in-memory Riverpod state to a brand-new empty project
    //    with a DYNAMIC, UNIQUE project id — NOT the hardcoded stale 'project_1'.
    //    This guarantees feature screens won't confuse the new session with
    //    the canceled one, and allows new writes/reads to Firestore.
    state = WeddingProject(id: _generateFreshProjectId());
  }
}
