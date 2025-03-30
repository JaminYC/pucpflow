// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/home_page.dart';
import 'package:pucpflow/splash_screen/user_profile_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _createUserProfileIfNeeded();
  }

  Future<void> _createUserProfileIfNeeded() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final userProfile = await _userProfileService.getUserProfile(user.uid);
      if (userProfile == null) {
        await _userProfileService.createUserProfile(user.uid, {
          "uid": user.uid,
          "name": user.displayName ?? "Nuevo Usuario",
          "email": user.email,
          "preferences": {
            "theme": "light",
            "language": "es",
            "notifications": true
          },
          "performance": {
            "global_score": 0,
            "tasks_pending": 0,
            "tasks_completed": 0
          },
          "schedule": {
            "monday": [],
            "tuesday": [],
            "wednesday": [],
            "thursday": [],
            "friday": [],
            "saturday": [],
            "sunday": []
          },
          "google_calendar_events": []
        });
      }
    }
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido a PUCP Flow"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "¡Bienvenido a PUCP Flow!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Configura tus preferencias para comenzar",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _navigateToHomePage,
              child: const Text("Continuar"),
            ),
          ],
        ),
      ),
    );
  }
}
