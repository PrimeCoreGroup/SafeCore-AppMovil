/// Estado del backend según `/health/ready` (comprueba MySQL).
class BackendHealth {
  const BackendHealth(
      {required this.ready, required this.checkedAt, this.detail});

  final bool ready;
  final DateTime checkedAt;
  final String? detail;
}
