import 'package:flutter/material.dart';

import '../widgets/auth_layout.dart';

/// El backend no tiene registro público ni recuperación de contraseña:
/// un administrador crea las cuentas (`POST /api/users`).
class AccessHelpPage extends StatelessWidget {
  const AccessHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        );
    return AuthLayout(
      showBack: true,
      title: 'Acceso a SafeCore',
      subtitle: 'Las cuentas las gestiona el administrador de tu organización.',
      children: [
        item(
          Icons.person_add_alt_1_rounded,
          '¿No tienes cuenta?',
          'Por seguridad no existe registro público. Pide a un administrador '
              'que te cree un usuario con el rol adecuado (Operador, Respondedor o Residente).',
        ),
        item(
          Icons.password_rounded,
          '¿Olvidaste tu contraseña?',
          'Solicita al administrador un restablecimiento. Las contraseñas deben '
              'tener entre 12 y 128 caracteres, con mayúscula, minúscula, número y símbolo.',
        ),
        item(
          Icons.lock_clock_rounded,
          '¿Cuenta bloqueada?',
          'Tras cinco intentos fallidos la cuenta se bloquea 15 minutos. '
              'Espera y vuelve a intentarlo.',
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Volver al inicio de sesión'),
        ),
      ],
    );
  }
}
