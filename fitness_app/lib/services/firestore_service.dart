import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/workout_session.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;



  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<AppUser?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.data()!, uid);
  }


  Stream<AppUser?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.data()!, uid);
    });
  }

  Future<void> updateUserProfile(AppUser user) {
    return _userDoc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }



  CollectionReference<Map<String, dynamic>> _workoutsCol(String uid) =>
      _userDoc(uid).collection('workouts');


  Future<String> saveWorkout(WorkoutSession session) async {
    final docRef = _workoutsCol(session.userId).doc();
    await docRef.set(session.toMap());
    return docRef.id;
  }


  Stream<List<WorkoutSession>> watchWorkouts(String uid) {
    return _workoutsCol(uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => WorkoutSession.fromMap(d.data(), d.id))
        .toList());
  }

  Future<void> deleteWorkout({required String uid, required String workoutId}) {
    return _workoutsCol(uid).doc(workoutId).delete();
  }
}