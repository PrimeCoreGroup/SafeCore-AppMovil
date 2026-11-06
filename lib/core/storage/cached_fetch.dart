import '../errors/failures.dart';
import '../utils/data_result.dart';
import 'local_cache.dart';

/// Estrategia "red primero, último estado conocido como respaldo".
///
/// 1. Intenta obtener los datos remotos y los guarda en caché.
/// 2. Si falla por conectividad, devuelve la copia local marcada como
///    `cache` y, si supera [staleAfter], como desactualizada.
/// 3. Si no hay copia local, propaga el error original.
///
/// Errores de autorización o validación NO usan la caché: no se debe mostrar
/// información a quien ya no tiene permiso.
Future<DataResult<T>> fetchWithCache<T>({
  required LocalCache cache,
  required String key,
  required Future<T> Function() remote,
  required Object? Function(T data) toJson,
  required T Function(Object? json) fromJson,
  required Duration staleAfter,
  DataSourceKind remoteKind = DataSourceKind.remote,
  DateTime Function() clock = DateTime.now,
}) async {
  try {
    final data = await remote();
    try {
      await cache.write(key, toJson(data));
    } catch (_) {
      // Un fallo de caché no debe impedir mostrar datos frescos.
    }
    return DataResult(data: data, source: remoteKind, fetchedAt: clock());
  } catch (error) {
    if (!isConnectivityFailure(error)) rethrow;
    final entry = await cache.read(key);
    if (entry == null) rethrow;
    return DataResult(
      data: fromJson(entry.value),
      source: DataSourceKind.cache,
      fetchedAt: entry.savedAt,
      isStale: clock().difference(entry.savedAt) > staleAfter,
    );
  }
}
