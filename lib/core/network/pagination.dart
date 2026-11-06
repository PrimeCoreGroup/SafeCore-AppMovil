/// Paginación del backend SafeCore: `?page=1&pageSize=N` (N ≤ 250) y la
/// respuesta es un arreglo directo sin total de registros.
typedef PageFetcher<T> = Future<List<T>> Function(int page, int pageSize);

const kMaxPageSize = 250;

/// Descarga páginas hasta recibir una incompleta (o vacía).
Future<List<T>> fetchAllPages<T>(
  PageFetcher<T> fetch, {
  int pageSize = kMaxPageSize,
  int maxPages = 20,
}) async {
  final all = <T>[];
  for (var page = 1; page <= maxPages; page++) {
    final items = await fetch(page, pageSize);
    all.addAll(items);
    if (items.length < pageSize) break;
  }
  return all;
}

/// Obtiene los [keep] elementos más recientes sin conocer el orden del
/// servidor ni el total (útil para telemetría, que crece sin límite).
///
/// Si la primera página está en orden descendente, basta con ella. Si es
/// ascendente, localiza la última página con un sondeo exponencial y una
/// búsqueda binaria, y descarga solo las páginas finales.
Future<List<T>> fetchNewest<T>(
  PageFetcher<T> fetch,
  DateTime Function(T item) dateOf, {
  int pageSize = kMaxPageSize,
  int keep = 500,
  int maxPage = 4096,
}) async {
  int byNewest(T a, T b) => dateOf(b).compareTo(dateOf(a));

  final first = await fetch(1, pageSize);
  if (first.length < pageSize) return [...first]..sort(byNewest);
  final descending = !dateOf(first.first).isBefore(dateOf(first.last));
  if (descending) {
    final result = [...first];
    var page = 2;
    while (result.length < keep) {
      final next = await fetch(page++, pageSize);
      result.addAll(next);
      if (next.length < pageSize) break;
    }
    return (result..sort(byNewest)).take(keep).toList();
  }

  // Orden ascendente: buscar la última página no vacía.
  final cache = <int, List<T>>{1: first};
  Future<List<T>> pageAt(int p) async => cache[p] ??= await fetch(p, pageSize);

  var lo = 1; // última página conocida completa
  int? hi; // primera página conocida vacía o incompleta
  var probe = 2;
  while (probe <= maxPage) {
    final items = await pageAt(probe);
    if (items.length < pageSize) {
      hi = probe;
      break;
    }
    lo = probe;
    probe *= 2;
  }
  hi ??= maxPage;
  while (hi! - lo > 1) {
    final mid = (lo + hi) ~/ 2;
    final items = await pageAt(mid);
    if (items.length < pageSize) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  // `hi` puede estar vacía o incompleta; `lo` está completa.
  final result = <T>[...await pageAt(hi), ...await pageAt(lo)];
  var page = lo - 1;
  while (result.length < keep && page >= 1) {
    result.addAll(await pageAt(page--));
  }
  return (result..sort(byNewest)).take(keep).toList();
}
