import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group("FirebaseAuthMocks - Google Login", () {
    test("Đăng nhập mock thành công", () async {
      // Tạo user giả lập
      final mockUser = MockUser(
        isAnonymous: false,
        uid: "mock_uid_123",
        email: "mockuser@gmail.com",
        displayName: "Mock User",
      );

      // Tạo MockFirebaseAuth với user giả
      final auth = MockFirebaseAuth(mockUser: mockUser);

      // Fake login bằng credential Google
      final result = await auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: "fake-id-token",
          accessToken: "fake-access-token",
        ),
      );

      final user = result.user;

      // Kiểm tra
      expect(user, isNotNull);
      expect(user?.uid, "mock_uid_123");
      expect(user?.email, "mockuser@gmail.com");
      expect(user?.displayName, "Mock User");
    });

    test("Đăng xuất mock thành công", () async {
      final mockUser = MockUser(uid: "logout_test", email: "logout@gmail.com");

      final auth = MockFirebaseAuth(mockUser: mockUser);

      await auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: "fake-id",
          accessToken: "fake-access",
        ),
      );

      expect(auth.currentUser, isNotNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });
}
