import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthState {
  final bool signedIn;
  final bool isAdmin;

  AuthState({required this.signedIn, required this.isAdmin});
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _controller = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authState => _controller.stream;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _controller.add(AuthState(signedIn: false, isAdmin: false));
        return;
      }

      final uid = user.uid;

      final adminDoc = await _firestore.collection('admin').doc(uid).get();
      final isAdmin = adminDoc.exists;

      _controller.add(AuthState(signedIn: true, isAdmin: isAdmin));
    });
  }

  Future<String?> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async => await _auth.signOut();

  User? get user => _auth.currentUser;
}
