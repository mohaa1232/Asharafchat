import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles every sign-in path AsharafChat supports and ensures a matching
/// `users/{uid}` document exists in Firestore — this is what lets any two
/// people who install the app find and message each other.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Step 1 of phone auth: sends the OTP SMS.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onFailed,
      codeSent: (verificationId, resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  /// Step 2 of phone auth: confirms the 6-digit code the user typed in.
  Future<UserCredential> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(result.user!);
    return result;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await result.user!.updateDisplayName(displayName);
    await _ensureUserDocument(result.user!, displayName: displayName);
    return result;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _ensureUserDocument(result.user!);
    return result;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(result.user!);
    return result;
  }

  /// Creates (or updates) the shared user profile document every other user
  /// reads from — this is the single source of truth that makes "install +
  /// register => immediately reachable by everyone else" work.
  Future<void> _ensureUserDocument(User user, {String? displayName}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'New User',
        'username': null,
        'bio': '',
        'photoUrl': user.photoURL,
        'status': 'Hey there! I am using AsharafChat.',
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'privacy': {
          'lastSeenVisible': true,
          'photoVisible': true,
          'statusVisible': true,
          'readReceipts': true,
        },
        'fcmTokens': <String>[],
      });
    } else {
      await ref.update({'online': true, 'lastSeen': FieldValue.serverTimestamp()});
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
