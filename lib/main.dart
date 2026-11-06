import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/storage/local_cache.dart';
import 'core/storage/sqflite_local_cache.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final problems = config.validate();
  if (problems.isNotEmpty) {
    // Configuración insegura o incompleta: no se arranca contra el backend.
    runApp(_ConfigErrorApp(problems: problems));
    return;
  }

  LocalCache cache;
  try {
    cache = await SqfliteLocalCache.open();
  } catch (e) {
    debugPrint(
        '[SafeCore] SQLite no disponible, se usa caché en memoria: ${e.runtimeType}');
    cache = InMemoryLocalCache();
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        localCacheProvider.overrideWithValue(cache),
      ],
      child: const SafeCoreApp(),
    ),
  );
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.problems});
  final List<String> problems;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.settings_outlined, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Configuración inválida',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final p in problems) Text('• $p'),
                  const SizedBox(height: 12),
                  const Text('Revisa tu archivo .env (ver README).'),
                ],
              ),
            ),
          ),
        ),
      );
}
