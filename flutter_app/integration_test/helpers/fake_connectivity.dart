import 'dart:async';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  final _controller =
      StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> _currentStatus = [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      _currentStatus;

  void goOffline() {
    _currentStatus = [ConnectivityResult.none];
    _controller.add(_currentStatus);
  }

  void goOnline() {
    _currentStatus = [ConnectivityResult.wifi];
    _controller.add(_currentStatus);
  }

  void dispose() => _controller.close();
}
