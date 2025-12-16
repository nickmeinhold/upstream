import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../services/transmission_client.dart';
import '../services/jackett_client.dart';
import '../services/omdb_client.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_watch_history.dart';
import '../services/download_mapping.dart';
import '../tmdb_client.dart';
import 'routes.dart';

class DownstreamServer {
  final int port;
  final String? staticPath;

  late final TmdbClient tmdb;
  late final TransmissionClient transmission;
  late final JackettClient? jackett;
  late final OmdbClient? omdb;
  late final FirebaseAuthService firebaseAuth;
  late final FirestoreWatchHistory watchHistory;
  late final DownloadMapping downloadMapping;

  DownstreamServer({
    this.port = 8080,
    this.staticPath,
  });

  Future<void> start() async {
    // Load config from environment
    final tmdbKey = Platform.environment['TMDB_API_KEY'];
    if (tmdbKey == null || tmdbKey.isEmpty) {
      throw Exception('TMDB_API_KEY environment variable required');
    }

    final firebaseProjectId = Platform.environment['FIREBASE_PROJECT_ID'];
    if (firebaseProjectId == null || firebaseProjectId.isEmpty) {
      throw Exception('FIREBASE_PROJECT_ID environment variable required');
    }

    final firebaseServiceAccount = Platform.environment['FIREBASE_SERVICE_ACCOUNT'];
    if (firebaseServiceAccount == null || firebaseServiceAccount.isEmpty) {
      throw Exception('FIREBASE_SERVICE_ACCOUNT environment variable required');
    }

    final transmissionUrl = Platform.environment['TRANSMISSION_URL'] ?? 'http://localhost:9091';
    final jackettUrl = Platform.environment['JACKETT_URL'];
    final jackettKey = Platform.environment['JACKETT_API_KEY'];
    final omdbKey = Platform.environment['OMDB_API_KEY'];

    // Initialize services
    tmdb = TmdbClient(tmdbKey);
    transmission = TransmissionClient(baseUrl: transmissionUrl);

    if (jackettUrl != null && jackettKey != null) {
      jackett = JackettClient(baseUrl: jackettUrl, apiKey: jackettKey);
    } else {
      jackett = null;
      print('Warning: Jackett not configured (JACKETT_URL and JACKETT_API_KEY required)');
    }

    if (omdbKey != null && omdbKey.isNotEmpty) {
      omdb = OmdbClient(omdbKey);
      print('  OMDB: Configured (IMDB/RT/Metacritic ratings enabled)');
    } else {
      omdb = null;
      print('Warning: OMDB not configured (OMDB_API_KEY required for ratings)');
    }

    // Initialize Firebase services
    firebaseAuth = FirebaseAuthService(projectId: firebaseProjectId);
    watchHistory = await FirestoreWatchHistory.create(
      projectId: firebaseProjectId,
      serviceAccountJson: firebaseServiceAccount,
    );
    print('  Firebase: Configured (project: $firebaseProjectId)');

    downloadMapping = DownloadMapping();
    await downloadMapping.load();

    // Build router
    final apiRoutes = ApiRoutes(
      tmdb: tmdb,
      transmission: transmission,
      jackett: jackett,
      omdb: omdb,
      firebaseAuth: firebaseAuth,
      watchHistory: watchHistory,
      downloadMapping: downloadMapping,
    );

    final router = Router();

    // Mount API routes
    router.mount('/api/', apiRoutes.router.call);

    // Health check
    router.get('/health', (Request request) {
      return Response.ok('OK');
    });

    // Build pipeline
    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders())
        .addHandler(router.call);

    // Add static file serving if path provided
    if (staticPath != null) {
      final staticHandler = createStaticHandler(
        staticPath!,
        defaultDocument: 'index.html',
      );

      handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(corsHeaders())
          .addMiddleware(_wasmHeaders())
          .addHandler((Request request) async {
            // Try API first
            if (request.url.path.startsWith('api/') ||
                request.url.path == 'health') {
              return router.call(request);
            }
            // Fall back to static files
            return staticHandler(request);
          });
    }

    // Start server
    final server = await io.serve(handler, InternetAddress.anyIPv4, port);
    print('Downstream server running at http://${server.address.host}:${server.port}');

    // Test connections
    await _testConnections();
  }

  /// Middleware to add headers required for WASM multi-threading support
  Middleware _wasmHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'Cross-Origin-Embedder-Policy': 'credentialless',
          'Cross-Origin-Opener-Policy': 'same-origin',
        });
      };
    };
  }

  Future<void> _testConnections() async {
    // Test Transmission
    if (await transmission.testConnection()) {
      print('  Transmission: Connected');
    } else {
      print('  Transmission: Not available');
    }

    // Test Jackett
    if (jackett != null && await jackett!.testConnection()) {
      print('  Jackett: Connected');
    } else if (jackett != null) {
      print('  Jackett: Not available');
    }
  }
}
