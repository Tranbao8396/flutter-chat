import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class Authentication {
  static bool isLoggedIn() {
    return !(FirebaseAuth.instance.currentUser == null);
  }

  static Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({'email': email, 'uid': FirebaseAuth.instance.currentUser!.uid, 'name': name});
      return userCredential;
    } catch (error) {
      Logger().e(error);
      return null;
    }
  }

  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } catch (error) {
      Logger().e(error);
      return null;
    }
  }

  static signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      Logger().e(error);
    }
  }
}
