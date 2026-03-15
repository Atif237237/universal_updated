import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_science_academy/core/services/connectivity_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: connectivityProvider.isOffline ? 30 : 0,
      color: Colors.red,
      child: const Center(
        child: Text(
          "You are currently offline",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
