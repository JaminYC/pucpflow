import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkIfUserProfileExists(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final docSnapshot = await userDoc.get();
    return docSnapshot.exists;
  }

  Future<void> createUserProfile(String userId, Map<String, dynamic> userProfileData) async {
    final userDoc = _firestore.collection('users').doc(userId);
    if (!(await userDoc.get()).exists) {
      await userDoc.set(userProfileData);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final docSnapshot = await userDoc.get();
    return docSnapshot.data();
  }

  Future<void> updateCalendarEvents(String userId, List<String> events) async {
    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.update({
      'calendarEvents': events,
    });
  }
}
