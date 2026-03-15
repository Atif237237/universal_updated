import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.none];
  bool _isInitialized = false;

  ConnectivityProvider() {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _connectivityResult = results;
      notifyListeners();
    });
    _initialize();
  }

  // Check initial connectivity
  Future<void> _initialize() async {
    _connectivityResult = await Connectivity().checkConnectivity();
    _isInitialized = true;
    notifyListeners();
  }

  // A simple getter to know if the device is offline
  bool get isOffline {
    if (!_isInitialized) return false; // Assume online until check is complete
    return _connectivityResult.contains(ConnectivityResult.none) ||
        _connectivityResult.isEmpty;
  }
}
