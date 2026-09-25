import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        await _auth.currentUser?.sendEmailVerification();
      } catch (_) {}

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to create account.";
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Authentication failed.";
    }
  }

  Future<String?> resetPasswordViaEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to send password reset email.";
    }
  }

  // Changing a password is a "sensitive" operation, so Firebase requires
  // the user to have signed in recently. We re-authenticate with their
  // current password first, then set the new one.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return "No logged-in user found.";
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to change password.";
    }
  }

  // Deleting the account is also sensitive, so we re-authenticate first.
  Future<String?> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return "No logged-in user found.";
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to delete account.";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}