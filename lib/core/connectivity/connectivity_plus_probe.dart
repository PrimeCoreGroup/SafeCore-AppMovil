import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_probe.dart';

class ConnectivityPlusProbe implements ConnectivityProbe {
  ConnectivityPlusProbe([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onChanged =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();
}
