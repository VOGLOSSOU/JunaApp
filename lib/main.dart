import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'core/services/deep_link_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: JunaApp()));
}

class JunaApp extends ConsumerStatefulWidget {
  const JunaApp({super.key});

  @override
  ConsumerState<JunaApp> createState() => _JunaAppState();
}

class _JunaAppState extends ConsumerState<JunaApp> {
  DeepLinkService? _deepLinkService;

  @override
  void initState() {
    super.initState();
    // Initialisé après le premier build pour que le router soit prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      _deepLinkService = DeepLinkService(router);
      _deepLinkService!.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Juna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
