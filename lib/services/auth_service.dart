import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, GoogleSignIn(), FirebaseFirestore.instance);
});

final userNameProvider = FutureProvider.family<String?, String>((ref, email) async {
  return ref.read(authServiceProvider).getUserNameByEmail(email);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth, this._googleSignIn, this._firestore);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserNameByEmail(String email) async {
    try {
      final snapshot = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['name'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
      });

      await credential.user!.updateDisplayName(name);

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // The user canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final credential = await _firebaseAuth.signInWithCredential(authCredential);
      
      if (credential.user != null) {
        final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'name': credential.user!.displayName ?? 'User',
            'email': credential.user!.email,
          });
        }
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
