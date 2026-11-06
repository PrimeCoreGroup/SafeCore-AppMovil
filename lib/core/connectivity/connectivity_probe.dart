/// Abstracción de la conectividad de red del dispositivo.
abstract interface class ConnectivityProbe {
  Future<bool> isOnline();
  Stream<bool> get onChanged;
}

/// Sonda fija para pruebas.
class FakeConnectivityProbe implements ConnectivityProbe {
  FakeConnectivityProbe({this.online = true});
  bool online;
  final _changes = <void Function(bool)>[];

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onChanged => Stream<bool>.multi((c) {
        void listener(bool v) => c.add(v);
        _changes.add(listener);
        c.onCancel = () => _changes.remove(listener);
      });

  void set(bool value) {
    online = value;
    for (final l in List.of(_changes)) {
      l(value);
    }
  }
}
