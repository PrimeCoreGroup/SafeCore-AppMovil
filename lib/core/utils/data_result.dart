/// Origen de los datos mostrados en pantalla.
enum DataSourceKind { remote, cache, demo }

/// Envoltorio de datos con metadatos de frescura.
///
/// Permite que la UI indique si la información viene de la nube, del
/// almacenamiento local (último estado conocido) o es de demostración, y si
/// está desactualizada.
class DataResult<T> {
  const DataResult({
    required this.data,
    required this.source,
    required this.fetchedAt,
    this.isStale = false,
  });

  final T data;
  final DataSourceKind source;
  final DateTime fetchedAt;
  final bool isStale;

  bool get fromCache => source == DataSourceKind.cache;
  bool get isDemo => source == DataSourceKind.demo;

  DataResult<R> map<R>(R Function(T data) transform) => DataResult<R>(
        data: transform(data),
        source: source,
        fetchedAt: fetchedAt,
        isStale: isStale,
      );
}
