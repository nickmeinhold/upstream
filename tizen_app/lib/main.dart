import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/b2_service.dart';
import 'services/omdb_service.dart';
import 'services/video_service.dart';
import 'screens/tv_home_screen.dart';
import 'widgets/tv/tv_keyboard_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final omdbService = OmdbService(apiKey: AppConfig.omdbApiKey);
  final b2Service = B2Service(
    manifestUrl: AppConfig.manifestUrl,
    omdbService: omdbService,
  );

  runApp(DownstreamTizenApp(b2Service: b2Service));
}

class DownstreamTizenApp extends StatelessWidget {
  final B2Service b2Service;

  const DownstreamTizenApp({
    super.key,
    required this.b2Service,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => VideoService(b2Service)),
        ProxyProvider<AuthService, ApiService>(
          update: (_, auth, __) => ApiService(auth),
        ),
      ],
      child: MaterialApp(
        title: 'Downstream',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const TvKeyboardHandler(
          child: TvHomeScreen(),
        ),
      ),
    );
  }
}
