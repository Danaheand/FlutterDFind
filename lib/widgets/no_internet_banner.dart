import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class NoInternetBanner extends StatelessWidget {
  const NoInternetBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        // Solo mostrar si no hay conexión
        if (connectivityProvider.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.red.shade600,
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Conectate a Internet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
