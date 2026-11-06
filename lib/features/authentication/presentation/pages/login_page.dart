import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/services/demo/demo_data_store.dart';
import '../../domain/services/auth_validators.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_layout.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _prefilled = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final error = await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  void _useDemo(DemoAccount a) {
    _email.text = a.email;
    _password.text = DemoDataStore.demoPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(authControllerProvider).notice;
    final demo = ref.watch(isDemoProvider);
    final last = ref.watch(lastEmailProvider).valueOrNull;
    if (!_prefilled && last != null && _email.text.isEmpty && !demo) {
      _prefilled = true;
      _email.text = last;
    }
    return AuthLayout(
      title: 'Iniciar sesión',
      subtitle: demo
          ? 'Modo demostración: datos ficticios, sin conexión al servidor.'
          : 'Accede a tu consola de protección IoT.',
      children: [
        if (!demo) const _ServerStatus(),
        if (notice != null && _error == null) FormErrorBanner(notice),
        if (_error != null) FormErrorBanner(_error!),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('login-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('login-password'),
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscure
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: AuthValidators.loginPassword,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('login-submit'),
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(_loading ? 'Ingresando…' : 'Iniciar sesión'),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.accessHelp),
                  child: const Text(
                      '¿No tienes cuenta u olvidaste tu contraseña?'),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
        if (!demo)
          OutlinedButton.icon(
            key: const Key('enter-demo'),
            onPressed: _loading
                ? null
                : () {
                    ref.read(authControllerProvider.notifier).setDemo(true);
                    _email.clear();
                    _password.clear();
                  },
            icon: const Icon(Icons.science_outlined),
            label: const Text('Explorar en modo demostración'),
          )
        else
          _DemoAccounts(
            onSelect: _loading ? null : _useDemo,
            onExit: () =>
                ref.read(authControllerProvider.notifier).setDemo(false),
            canExit: !ref.read(appConfigProvider).demoMode,
          ),
      ],
    );
  }
}

/// Estado del backend (`/health/ready`) visible antes de iniciar sesión.
class _ServerStatus extends ConsumerWidget {
  const _ServerStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);
    final (tone, icon, text) = health.when(
      data: (h) => h.ready
          ? (
              context.status.normal,
              Icons.cloud_done_rounded,
              'Servidor SafeCore en línea'
            )
          : (
              context.status.warning,
              Icons.cloud_off_rounded,
              'Servidor disponible, base de datos no lista'
            ),
      loading: () => (
        context.status.info,
        Icons.cloud_sync_rounded,
        'Comprobando servidor…'
      ),
      error: (_, __) => (
        context.status.offline,
        Icons.cloud_off_rounded,
        'No se pudo contactar al servidor'
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: tone.background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tone.foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: tone.foreground, fontWeight: FontWeight.w600)),
            ),
            if (health.hasError || health.valueOrNull?.ready == false)
              IconButton(
                tooltip: 'Reintentar',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.refresh_rounded, color: tone.foreground),
                onPressed: () => ref.invalidate(healthProvider),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts(
      {required this.onSelect, required this.onExit, required this.canExit});

  final void Function(DemoAccount)? onSelect;
  final VoidCallback onExit;
  final bool canExit;

  @override
  Widget build(BuildContext context) {
    final tone = context.status.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: tone.background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: tone.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuentas de demostración',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Datos ficticios. Contraseña: ${DemoDataStore.demoPassword}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in DemoDataStore.accounts)
                ActionChip(
                  avatar: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text(a.description),
                  onPressed: onSelect == null ? null : () => onSelect!(a),
                ),
            ],
          ),
          if (canExit) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.cloud_outlined),
              label: const Text('Volver al servidor real'),
            ),
          ],
        ],
      ),
    );
  }
}
