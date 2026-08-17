import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../models/wedding_project_model.dart';
import 'auth_session_service.dart';
import 'wedding_project_provider.dart';

const String notificationRouteDashboard = 'dashboard';
const String notificationRouteCheckout = 'checkout';
const String notificationRouteReceipt = 'receipt';
const String notificationRouteSupport = 'support';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  final project = ref.watch(weddingProjectProvider);
  final email = ref.watch(authStateProvider).email;
  return NotificationNotifier(userEmail: email, project: project);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationProvider)
      .where((notification) => !notification.isRead && !notification.isExpired)
      .length;
});

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  final String? userEmail;
  final WeddingProject project;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  NotificationNotifier({required this.userEmail, required this.project}) : super([]) {
    _start();
  }

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) return user.uid;
    if (userEmail != null && userEmail!.isNotEmpty) {
      return userEmail!.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    }
    return 'default_user';
  }

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('user_wedding_projects')
      .doc(_userId)
      .collection('notifications');

  Future<void> _start() async {
    if (_userId == 'default_user') return;
    _subscription = _collection.orderBy('createdAt', descending: true).snapshots().listen(
      (snapshot) {
        state = snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
            .toList();
      },
    );
    await synchronizeProjectState();
  }

  Future<void> _ensureActive({
    required String id,
    required String title,
    required String body,
    required String targetRoute,
  }) async {
    final reference = _collection.doc(id);
    final existing = await reference.get();
    if (existing.exists) {
      await reference.set({
        'title': title,
        'body': body,
        'targetRoute': targetRoute,
        'isExpired': false,
      }, SetOptions(merge: true));
      return;
    }
    await reference.set(
      NotificationModel(
        id: id,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        targetRoute: targetRoute,
      ).toMap(),
    );
  }

  Future<void> _expire(String id) async {
    final reference = _collection.doc(id);
    if (!(await reference.get()).exists) return;
    await reference.set({
      'isExpired': true,
      'isRead': true,
    }, SetOptions(merge: true));
  }

  /// Creates and resolves alerts from the authoritative WeddingProject state.
  Future<void> synchronizeProjectState([WeddingProject? latestProject]) async {
    if (_userId == 'default_user') return;
    final currentProject = latestProject ?? project;

    if (currentProject.isPaid) {
      // Payment completion fulfils both the original checkout request and any
      // post-payment balance adjustment.
      await _expire('payment_required');
      await _expire('outstanding_balance');
      await _ensureActive(
        id: 'payment_confirmed_${currentProject.transactionId ?? currentProject.id}',
        title: 'Payment Confirmed! 🎉',
        body:
            'Your wedding project payment has been processed successfully. Your venue, catering, and planning details are locked in!',
        targetRoute: notificationRouteReceipt,
      );
    } else if (currentProject.isFullyCompleted) {
      if (currentProject.amountPaid > 0 && currentProject.balanceDue > 0) {
        await _ensureActive(
          id: 'outstanding_balance',
          title: 'Outstanding Balance',
          body:
              'Your updated order requires an additional payment of RM ${currentProject.balanceDue.toStringAsFixed(2)} to confirm changes.',
          targetRoute: notificationRouteCheckout,
        );
      } else {
        await _ensureActive(
          id: 'payment_required',
          title: 'Payment Required',
          body:
              'You have completed all 4 planning steps! Please proceed to checkout to finalize your booking.',
          targetRoute: notificationRouteCheckout,
        );
      }
    }

    if (currentProject.pendingRefundAmount > 0) {
      await _ensureActive(
        id: 'refund_processing',
        title: 'Refund Processing',
        body:
            'Your updated order total is lower. Our team will contact you via email regarding your refund.',
        targetRoute: notificationRouteSupport,
      );
    }

    final weddingDate = currentProject.weddingDate;
    if (weddingDate != null) {
      final daysUntilWedding = weddingDate.difference(DateTime.now()).inDays;
      if (daysUntilWedding >= 0 && daysUntilWedding <= 7) {
        await _ensureActive(
          id: 'wedding_countdown_${weddingDate.toIso8601String().split('T').first}',
          title: 'Wedding Day Countdown! 💍',
          body: 'Your big day is 1 week away! Review your final arrangements.',
          targetRoute: notificationRouteDashboard,
        );
      }
    }
  }

  Future<void> markRead(String id) async {
    if (_userId == 'default_user') return;
    await _collection.doc(id).set({'isRead': true}, SetOptions(merge: true));
  }

  Future<void> markAllRead() async {
    if (_userId == 'default_user') return;
    final unread = await _collection.where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
