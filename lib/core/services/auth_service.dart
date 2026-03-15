import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Updated Admin Sign In with Role Check
  Future<User?> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Sign in the user normally
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Step 2: Check the user's role from Firestore
        DocumentSnapshot userDoc = await _db
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.get('role') == 'admin') {
          // Step 3: If role is 'admin', login is successful
          return user;
        } else {
          // If role is not 'admin' or document doesn't exist, sign them out
          await _auth.signOut();
          throw Exception('Access Denied: Not an admin user.');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Re-throw the auth exception to show it in the UI
      throw Exception(e.message);
    } catch (e) {
      // Re-throw our custom exception
      throw Exception(e.toString());
    }
  }

  // Teacher Sign In (This can remain the same or be updated similarly if needed)
  // ... your existing teacher login logic ...

  // Forgot Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }
}
