import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run bin/reset_request.dart <mediaKey>');
    print('Example: dart run bin/reset_request.dart movie_51876');
    return;
  }

  final mediaKey = args[0];

  final envContent = File('.env').readAsStringSync();
  final match = RegExp(r"FIREBASE_SERVICE_ACCOUNT='(.+)'").firstMatch(envContent);
  if (match == null) {
    print('Could not find service account');
    return;
  }

  final serviceAccountJson = json.decode(match.group(1)!);
  final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  final scopes = [FirestoreApi.datastoreScope];

  final client = await clientViaServiceAccount(credentials, scopes);
  final firestore = FirestoreApi(client);

  final projectId = 'downstream-181e2';
  final docPath = 'projects/$projectId/databases/(default)/documents/requests/$mediaKey';

  final newStatus = args.length > 1 ? args[1] : 'pending';

  try {
    if (args.contains('--delete')) {
      await firestore.projects.databases.documents.delete(docPath);
      print('Deleted $mediaKey');
    } else {
      final clearError = args.contains('--clear-error');
      final fieldPaths = ['status'];
      final fields = <String, Value>{
        'status': Value(stringValue: newStatus),
      };
      if (clearError) {
        fieldPaths.add('errorMessage');
        fields['errorMessage'] = Value(nullValue: 'NULL_VALUE');
      }
      await firestore.projects.databases.documents.patch(
        Document(fields: fields),
        docPath,
        updateMask_fieldPaths: fieldPaths,
      );
      print('Set $mediaKey to $newStatus${clearError ? ' (cleared error)' : ''}');
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
