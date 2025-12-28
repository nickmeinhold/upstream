import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

void main() async {
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
  final parent = 'projects/$projectId/databases/(default)/documents';

  try {
    final requests = await firestore.projects.databases.documents.listDocuments(
      parent,
      'requests',
    );

    print('=== Content Requests in Firestore ===\n');
    if (requests.documents == null || requests.documents!.isEmpty) {
      print('No requests found.');
    } else {
      for (final doc in requests.documents!) {
        final fields = doc.fields!;
        print('Title: ${fields['title']?.stringValue ?? 'N/A'}');
        print('Type: ${fields['mediaType']?.stringValue ?? 'N/A'}');
        print('TMDB ID: ${fields['tmdbId']?.integerValue ?? 'N/A'}');
        print('Status: ${fields['status']?.stringValue ?? 'N/A'}');
        final error = fields['errorMessage']?.stringValue;
        if (error != null) print('Error: $error');
        final dlProgress = fields['downloadProgress']?.doubleValue;
        if (dlProgress != null) print('Download Progress: ${(dlProgress * 100).toStringAsFixed(1)}%');
        final tcProgress = fields['transcodingProgress']?.doubleValue;
        if (tcProgress != null) print('Transcode Progress: ${(tcProgress * 100).toStringAsFixed(1)}%');
        final upProgress = fields['uploadProgress']?.doubleValue;
        if (upProgress != null) print('Upload Progress: ${(upProgress * 100).toStringAsFixed(1)}%');
        final storagePath = fields['storagePath']?.stringValue;
        if (storagePath != null) print('Storage Path: $storagePath');
        print('Requested By: ${fields['requestedBy']?.stringValue ?? 'N/A'}');
        print('Requested At: ${fields['requestedAt']?.timestampValue ?? 'N/A'}');
        print('---');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
