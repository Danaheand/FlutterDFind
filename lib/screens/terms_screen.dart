import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones de Uso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Aceptación de los Términos',
              'Al acceder y utilizar esta aplicación, aceptas estar sujeto a estos términos y condiciones de uso. Si no estás de acuerdo con alguno de estos términos, no debes usar esta aplicación.',
            ),
            _buildSection(
              'Registro de Usuario',
              'Para utilizar ciertas funciones de la aplicación, deberás registrarte proporcionando información precisa y actualizada. Eres responsable de mantener la confidencialidad de tu cuenta y contraseña.',
            ),
            _buildSection(
              'Uso de la Aplicación',
              'La aplicación está diseñada para ayudarte a gestionar inventarios y recordatorios. Te comprometes a usar la aplicación solo para fines legítimos y de acuerdo con todas las leyes y regulaciones aplicables.',
            ),
            _buildSection(
              'Privacidad',
              'Tu privacidad es importante para nosotros. Toda la información personal que proporcionas se maneja de acuerdo con nuestra Política de Privacidad.',
            ),
            _buildSection(
              'Limitación de Responsabilidad',
              'La aplicación se proporciona "tal cual" y "según disponibilidad". No garantizamos que la aplicación será ininterrumpida, oportuna o libre de errores.',
            ),
            _buildSection(
              'Modificaciones',
              'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor inmediatamente después de su publicación en la aplicación.',
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Última actualización: 6 de noviembre de 2025',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
