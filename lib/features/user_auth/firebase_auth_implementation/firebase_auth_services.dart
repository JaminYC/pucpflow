import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../global/common/toast.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro de usuario con email y contraseña
  Future<User?> signUpWithEmailAndPassword(String email, String password, String username) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
          'lifestyle': {
            'wake_up_time': "06:30 AM",
            'sleep_time': "11:00 PM",
            'exercise_days': ["Monday", "Wednesday", "Friday"],
            'exercise_type': "Cardio"
          },
          'preferences': {
            'theme': 'light',
            'language': 'en',
            'notifications': true,
          },
          'performance': {
            'global_score': 0,
            'tasks_completed': 0,
            'tasks_pending': 0,
          },
          'schedule': {
            'monday': [],
            'tuesday': [],
            'wednesday': [],
            'thursday': [],
            'friday': [],
            'saturday': [],
            'sunday': []
          },
        });

        print("User data saved successfully in Firestore!");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  // Inicio de sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  // Sign-In con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: "547054267025-aca3345kbjr3f61uh9aqbn8fg4hnmi05.apps.googleusercontent.com",
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        showToast(message: 'Sign-in cancelled by user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'username': googleUser.displayName ?? "User",
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
            'lifestyle': {
              'wake_up_time': "06:30 AM",
              'sleep_time': "11:00 PM",
              'exercise_days': ["Monday", "Wednesday", "Friday"],
              'exercise_type': "Cardio"
            },
            'preferences': {
              'theme': 'light',
              'language': 'en',
              'notifications': true,
            },
            'performance': {
              'global_score': 0,
              'tasks_completed': 0,
              'tasks_pending': 0,
            },
            'schedule': {
              'monday': [],
              'tuesday': [],
              'wednesday': [],
              'thursday': [],
              'friday': [],
              'saturday': [],
              'sunday': []
            },
          });

          print("Google user data saved successfully in Firestore!");
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      showToast(message: 'FirebaseAuthException: ${e.message}');
      return null;
    } catch (e) {
      showToast(message: 'Error during Google Sign-In: $e');
      return null;
    }
  }
}
