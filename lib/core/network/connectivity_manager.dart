import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_info.dart';

class ConnectivityManager {
  ConnectivityManager._();

  static final ConnectivityManager instance = ConnectivityManager._();

  final NetworkInfo _networkInfo = NetworkInfo();
  final StreamController<bool> _onlineController = StreamController<bool>.broadcast();

  bool _initialized = false;
  bool _lastKnownOnline = true;

  bool get isInitialized => _initialized;
  bool get lastKnownOnline => _lastKnownOnline;

  Stream<bool> get onlineStream => _onlineController.stream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _lastKnownOnline = await _networkInfo.isConnected;
    _onlineController.add(_lastKnownOnline);
    Connectivity().onConnectivityChanged.listen((results) {
      final online = results.isNotEmpty && results.first != ConnectivityResult.none;
      if (online != _lastKnownOnline) {
        _lastKnownOnline = online;
        _onlineController.add(online);
      }
    });
  }

  Future<bool> checkOnline() async {
    _lastKnownOnline = await _networkInfo.isConnected;
    return _lastKnownOnline;
  }

  void dispose() {
    _onlineController.close();
  }
}
