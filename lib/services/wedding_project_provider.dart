import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wedding_project_model.dart';
import 'auth_session_service.dart';

const String _kWeddingProjectKey = 'wedify_active_wedding_project';

final weddingProjectProvider = StateNotifierProvider<WeddingProjectNotifier, WeddingProject>((ref) {
  final authState = ref.watch(authStateProvider);
  return WeddingProjectNotifier(userEmail: authState.email);
});

class WeddingProjectNotifier extends StateNotifier<WeddingProject> {
  final String? userEmail;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WeddingProjectNotifier({this.userEmail}) : super(const WeddingProject(id: 'project_1')) {
    _loadProject();
  }

  String _sanitizeDocId(String email) {
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

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
        final doc = await _firestore.collection('user_wedding_projects').doc(userId).get();
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
      final String? jsonStr = prefs.getString('${_kWeddingProjectKey}_$_currentUserId');
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
      await prefs.setString('${_kWeddingProjectKey}_$_currentUserId', state.toJson());
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

  Future<void> setDateTime(DateTime date, String time) async {
    state = state.copyWith(
      weddingDate: date,
      weddingTime: time,
    );
    await _autoSave();
  }

  Future<void> updateVenue({
    required String venueName,
    required double fee,
    bool isCompleted = true,
  }) async {
    state = state.copyWith(
      selectedVenueName: venueName,
      venueFee: fee,
      isVenueCompleted: isCompleted,
    );
    await _autoSave();
  }

  Future<void> updatePlannerLayout({
    required String layoutSummary,
    required double fee,
    bool isCompleted = true,
  }) async {
    state = state.copyWith(
      plannerLayoutSummary: layoutSummary,
      plannerFee: fee,
      isPlannerCompleted: isCompleted,
    );
    await _autoSave();
  }

  Future<void> updateInvitation({
    required String invitationName,
    required double fee,
    bool isCompleted = true,
  }) async {
    state = state.copyWith(
      selectedInvitationName: invitationName,
      invitationFee: fee,
      isInvitationCompleted: isCompleted,
    );
    await _autoSave();
  }

  Future<void> updateCatering({
    required String cateringPackage,
    required double fee,
    bool isCompleted = true,
  }) async {
    state = state.copyWith(
      selectedCateringPackage: cateringPackage,
      cateringFee: fee,
      isCateringCompleted: isCompleted,
    );
    await _autoSave();
  }

  Future<void> resetProject() async {
    final userId = _currentUserId;
    state = const WeddingProject(id: 'project_1');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_kWeddingProjectKey}_$userId');

    if (userId != 'default_user') {
      try {
        await _firestore.collection('user_wedding_projects').doc(userId).delete();
      } catch (e) {
        // Handle deletion error
      }
    }
  }
}
