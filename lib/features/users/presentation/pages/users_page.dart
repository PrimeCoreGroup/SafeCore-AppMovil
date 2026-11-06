import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/roles.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/domain/services/auth_validators.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/managed_user.dart';

/// Gestión de usuarios (solo Administrator). Cumple US1: el alta de cuentas
/// la realiza un administrador; el backend no tiene registro público.
class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final me = ref.watch(currentUserProvider);
    final repo = ref.read(usersRepositoryProvider);

    Future<void> create() async {
      final data = await showModalBottomSheet<NewUserData>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const _NewUserForm(),
      );
      if (data == null || !context.mounted) return;
      await runRemoteAction(
        context,
        ref,
        action: () => repo.create(data),
        successMessage:
            'Usuario ${data.email} creado. Comparte la contraseña por un canal seguro.',
        auditAction: 'user.create',
        invalidate: [usersProvider],
      );
    }

    Future<void> edit(ManagedUser u) async {
      final result = await showModalBottomSheet<(String, String, UserStatus)>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _EditUserForm(user: u, isSelf: u.id == me?.id),
      );
      if (result == null || !context.mounted) return;
      await runRemoteAction(
        context,
        ref,
        action: () => repo.update(u.id,
            firstName: result.$1, lastName: result.$2, status: result.$3),
        successMessage: 'Usuario actualizado.',
        auditAction: 'user.update',
        invalidate: [usersProvider],
      );
    }

    Future<void> delete(ManagedUser u) async {
      final ok = await showConfirmDialog(
        context,
        title: '¿Eliminar a ${u.fullName}?',
        message:
            'No es posible si es el último administrador, tu propia cuenta o si '
            'tiene notificaciones asociadas. En esos casos, deshabilita la cuenta.',
        confirmLabel: 'Eliminar',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await runRemoteAction(
        context,
        ref,
        action: () => repo.delete(u.id),
        successMessage: 'Usuario eliminado.',
        auditAction: 'user.delete',
        invalidate: [usersProvider],
      );
    }

    return ScPage(
      title: 'Usuarios',
      subtitle: 'Cuentas y roles de acceso',
      onRefresh: () {
        ref.invalidate(usersProvider);
        return settle([ref.read(usersProvider.future)]);
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: create,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Crear usuario'),
      ),
      children: [
        AsyncValueView(
          value: users,
          onRetry: () => ref.invalidate(usersProvider),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DataFreshnessNote(r),
              for (final u in r.data) ...[
                SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        child: Text(u.fullName.isEmpty
                            ? '?'
                            : u.fullName[0].toUpperCase())),
                    title:
                        Text('${u.fullName}${u.id == me?.id ? ' (tú)' : ''}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.email),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final role in u.roles)
                              StatusChip(
                                  label: role.label, tone: context.status.info),
                            StatusChip(
                              label: u.status.label,
                              tone: u.status == UserStatus.active
                                  ? context.status.normal
                                  : context.status.offline,
                            ),
                          ],
                        ),
                        if (u.createdAt != null)
                          Text('Creado ${DateFormatter.day(u.createdAt!)}',
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      onSelected: (v) => v == 'edit' ? edit(u) : delete(u),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar nombre o estado')),
                        if (u.id != me?.id)
                          const PopupMenuItem(
                              value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                ),
                kGap,
              ],
              Text(
                'El email, la contraseña y el rol no se pueden cambiar después de crear la cuenta.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewUserForm extends StatefulWidget {
  const _NewUserForm();

  @override
  State<_NewUserForm> createState() => _NewUserFormState();
}

class _NewUserFormState extends State<_NewUserForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  UserRole _role = UserRole.resident;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_email, _password, _first, _last]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Crear usuario',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _first,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => AuthValidators.personName(v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _last,
                        decoration:
                            const InputDecoration(labelText: 'Apellido'),
                        validator: (v) =>
                            AuthValidators.personName(v, field: 'apellido'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Correo electrónico'),
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña inicial',
                    helperText:
                        '12–128 caracteres con mayúscula, minúscula, número y símbolo',
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: AuthValidators.newPassword,
                ),
                const SizedBox(height: 16),
                Text('Rol', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                for (final r in UserRole.assignable)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Icon(_role == r
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                      title: Text(r.label),
                      subtitle: Text(r.description),
                      onTap: () => setState(() => _role = r),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    Navigator.of(context).pop(
                      NewUserData(
                        email: _email.text,
                        password: _password.text,
                        firstName: _first.text,
                        lastName: _last.text,
                        role: _role,
                      ),
                    );
                  },
                  child: const Text('Crear usuario'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EditUserForm extends StatefulWidget {
  const _EditUserForm({required this.user, required this.isSelf});
  final ManagedUser user;
  final bool isSelf;

  @override
  State<_EditUserForm> createState() => _EditUserFormState();
}

class _EditUserFormState extends State<_EditUserForm> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.user.firstName);
  late final _last = TextEditingController(text: widget.user.lastName);
  late UserStatus _status = widget.user.status;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar ${widget.user.email}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => AuthValidators.personName(v)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (v) =>
                      AuthValidators.personName(v, field: 'apellido')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _status == UserStatus.active,
                onChanged: widget.isSelf
                    ? null
                    : (v) => setState(() =>
                        _status = v ? UserStatus.active : UserStatus.disabled),
                title: const Text('Cuenta activa'),
                subtitle: Text(widget.isSelf
                    ? 'No puedes deshabilitar tu propia cuenta.'
                    : 'Una cuenta deshabilitada no puede iniciar sesión.'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!(_form.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop((_first.text, _last.text, _status));
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );
}
