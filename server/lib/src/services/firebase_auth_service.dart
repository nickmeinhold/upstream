import 'dart:convert';

class FirebaseAuthService {
  final String projectId;

  FirebaseAuthService({required this.projectId});

  /// Verify a Firebase ID token and return the user info.
  ///
  /// Firebase ID tokens are JWTs issued by Firebase Auth. We validate:
  /// - iss (issuer) matches https://securetoken.google.com/{projectId}
  /// - aud (audience) matches the project ID
  /// - exp (expiration) is in the future
  /// - sub (subject/uid) is present
  ///
  /// Note: For production, you should also verify the signature using
  /// Google's public keys. Cloud Run's IAM provides additional security.
  Future<FirebaseUser?> verifyIdToken(String idToken) async {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      // Validate claims
      final iss = payload['iss'] as String?;
      final aud = payload['aud'] as String?;
      final exp = payload['exp'] as int?;
      final iat = payload['iat'] as int?;
      final sub = payload['sub'] as String?;

      if (iss != 'https://securetoken.google.com/$projectId') {
        print('Invalid issuer: $iss');
        return null;
      }
      if (aud != projectId) {
        print('Invalid audience: $aud');
        return null;
      }
      if (sub == null || sub.isEmpty) {
        print('Missing subject');
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (exp == null || exp < now) {
        print('Token expired');
        return null;
      }
      if (iat == null || iat > now + 60) {
        // Allow 60 seconds clock skew
        print('Token issued in the future');
        return null;
      }

      return FirebaseUser(
        uid: sub,
        email: payload['email'] as String?,
        name: payload['name'] as String?,
        picture: payload['picture'] as String?,
      );
    } catch (e) {
      print('Token verification error: $e');
      return null;
    }
  }
}

class FirebaseUser {
  final String uid;
  final String? email;
  final String? name;
  final String? picture;

  FirebaseUser({
    required this.uid,
    this.email,
    this.name,
    this.picture,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'picture': picture,
      };
}
