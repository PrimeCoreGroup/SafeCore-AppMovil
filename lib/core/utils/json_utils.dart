/// Utilidades de lectura defensiva de JSON proveniente del backend.
///
/// Evitan casts sin verificar (strict-casts) y devuelven valores neutros
/// cuando el contrato no trae un campo, en lugar de romper la pantalla.
typedef Json = Map<String, dynamic>;

Json asJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}

List<Json> asJsonList(Object? value) {
  if (value is List) return value.map(asJson).toList();
  return const [];
}

/// El backend SafeCore responde arreglos directos. Por tolerancia se aceptan
/// también envoltorios `{data}`, `{content}` o `{items}`.
/// Muchos backends envuelven la respuesta en `{ "data": ... }` o
/// paginan en `{ "content": [...] }`. Se aceptan ambas formas.
Object? unwrapData(Object? body) {
  if (body is Map && body.length <= 3) {
    if (body.containsKey('data') && body['data'] is! String) {
      return body['data'];
    }
    if (body['content'] is List) return body['content'];
    if (body['items'] is List) return body['items'];
  }
  return body;
}

String readString(Json json, String key, [String fallback = '']) {
  final v = json[key];
  if (v == null) return fallback;
  return v.toString();
}

String? readStringOrNull(Json json, String key) {
  final v = json[key];
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

double? readDouble(Json json, String key) {
  final v = json[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? readInt(Json json, String key) {
  final v = json[key];
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v);
  return null;
}

bool readBool(Json json, String key, {bool fallback = false}) {
  final v = json[key];
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return fallback;
}

List<String> readStringList(Json json, String key) {
  final v = json[key];
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}

/// Busca un valor de enum por su nombre en formato API (`POWER_CUT`) o Dart
/// (`powerCut`). Devuelve [fallback] si no se reconoce.
T enumFromApi<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw == null) return fallback;
  final normalized =
      raw.toString().replaceAll('_', '').replaceAll('-', '').toLowerCase();
  for (final v in values) {
    if (v.name.toLowerCase() == normalized) return v;
  }
  return fallback;
}

/// `powerCut` -> `POWER_CUT`
String enumToApi(Enum value) => value.name
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toUpperCase();
