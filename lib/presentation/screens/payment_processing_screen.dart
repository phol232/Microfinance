import 'package:flutter/material.dart';

class PaymentProcessingScreen extends StatelessWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onError;
  
  const PaymentProcessingScreen({
    Key? key,
    this.onComplete,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ejecutar el callback cuando el widget se monte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onComplete != null) {
        // Ejecutar el callback inmediatamente
        onComplete?.call();
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de carga animado
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Procesando Pago',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Por favor espera mientras procesamos tu pago...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

