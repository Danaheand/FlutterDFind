import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidad')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Política de Privacidad',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Esta aplicación recopila y almacena datos básicos de usuario como nombre y correo electrónico únicamente para la gestión de cuentas y acceso a las funcionalidades principales. No compartimos tu información personal con terceros y todos los datos se guardan de forma segura en tu dispositivo. Puedes eliminar tu cuenta y datos en cualquier momento desde la configuración.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'La app utiliza almacenamiento local para mantener tu sesión y lista de usuarios registrados. No se realiza seguimiento ni análisis de tu actividad fuera de la app.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Si tienes dudas sobre la privacidad o deseas ejercer tus derechos de acceso, rectificación o eliminación, puedes contactarnos desde la sección de soporte.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              Text(
                'Última actualización: Noviembre 2025',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
