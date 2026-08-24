import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  NetworkInfo([Connectivity? connectivity]) : _connectivity = connectivity ?? _instance;

  static final Connectivity _instance = Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }
}
