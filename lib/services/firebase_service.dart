import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/models/wizard_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// Sign in anonymously. Safe to call multiple times — returns existing user
  /// if already authenticated.
  Future<User> ensureAnonymousAuth() async {
    if (_auth.currentUser != null) return _auth.currentUser!;
    final creds = await _auth.signInAnonymously();
    return creds.user!;
  }

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Creations collection helpers ────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _creationsRef =>
      _firestore.collection('creations');

  // ── Save ────────────────────────────────────────────────────────────────────

  /// Saves a finished creation to Firestore. Returns the new document ID.
  Future<String> saveCreation({
    required WizardState wizardState,
    required String generatedHtml,
    required String summary,
    ParsedKidInput? parsedInput,
  }) async {
    final user = await ensureAnonymousAuth();

    // Convert int-keyed map to string-keyed map for Firestore
    final wizardAnswersStringKeyed = wizardState.answers.map(
      (k, v) => MapEntry(k.toString(), v),
    );

    final data = <String, dynamic>{
      'userId': user.uid,
      'creationType': wizardState.creationType,
      'wizardAnswers': wizardAnswersStringKeyed,
      'generatedHtml': generatedHtml,
      'summary': summary,
      'createdAt': FieldValue.serverTimestamp(),
      if (parsedInput != null) 'parsedInput': parsedInput.toJson(),
    };

    final doc = await _creationsRef.add(data);
    return doc.id;
  }

  // ── Fetch ────────────────────────────────────────────────────────────────────

  /// Fetches all creations for the current user, newest first.
  Future<List<CreationRecord>> fetchUserCreations() async {
    final user = await ensureAnonymousAuth();

    final snapshot = await _creationsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return CreationRecord.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  /// Stream version for real-time updates (used by the gallery).
  Stream<List<CreationRecord>> watchUserCreations() async* {
    final user = await ensureAnonymousAuth();

    yield* _creationsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreationRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteCreation(String docId) =>
      _creationsRef.doc(docId).delete();
}

// ── Data class for reading back from Firestore ──────────────────────────────

class CreationRecord {
  final String id;
  final String creationType;
  final Map<String, String> wizardAnswers;
  final String generatedHtml;
  final String summary;
  final DateTime? createdAt;
  final ParsedKidInput? parsedInput;

  CreationRecord({
    required this.id,
    required this.creationType,
    required this.wizardAnswers,
    required this.generatedHtml,
    required this.summary,
    this.createdAt,
    this.parsedInput,
  });

  factory CreationRecord.fromFirestore(
      String id, Map<String, dynamic> data) {
    final rawAnswers = data['wizardAnswers'] as Map<String, dynamic>? ?? {};
    final answers = rawAnswers.map((k, v) => MapEntry(k, v.toString()));

    ParsedKidInput? parsed;
    if (data['parsedInput'] != null) {
      parsed = ParsedKidInput.fromJson(
          Map<String, dynamic>.from(data['parsedInput'] as Map));
    }

    final ts = data['createdAt'] as Timestamp?;

    return CreationRecord(
      id: id,
      creationType: data['creationType'] as String? ?? '',
      wizardAnswers: answers,
      generatedHtml: data['generatedHtml'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      createdAt: ts?.toDate(),
      parsedInput: parsed,
    );
  }

  String get typeEmoji {
    switch (creationType) {
      case 'dartgame': return '🎮';
      case 'story': return '📖';
      case 'drawing': return '🎨';
      default: return '✨';
    }
  }

  String get typeLabel {
    switch (creationType) {
      case 'dartgame': return 'Game';
      case 'story': return 'Story';
      case 'drawing': return 'Drawing';
      default: return 'Creation';
    }
  }
}
