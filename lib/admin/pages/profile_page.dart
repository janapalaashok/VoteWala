import 'package:flutter/material.dart';

import '../admin_widgets.dart';

/// The signed-in admin: name, username, password.
class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final name = admin.displayName?.isNotEmpty == true ? admin.displayName! : admin.username;
    return AdminPage(
      title: 'My profile',
      subtitle: 'Your admin account. Keep your password private and change it regularly.',
      children: [
        AdminCard(
          child: Row(children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AdminColors.accent.withValues(alpha: 0.15),
              child: Text(name.isEmpty ? 'A' : name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AdminColors.accent)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Username: ${admin.username}', style: const TextStyle(color: AdminColors.muted)),
                Text('Role: ${admin.role}', style: const TextStyle(color: AdminColors.muted)),
              ]),
            ),
            OutlinedButton.icon(onPressed: admin.signOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
          ]),
        ),
        const _NameCard(),
        const _UsernameCard(),
        const AdminCard(title: 'Change password', child: ChangePasswordForm()),
      ],
    );
  }
}

class _NameCard extends StatefulWidget {
  const _NameCard();

  @override
  State<_NameCard> createState() => _NameCardState();
}

class _NameCardState extends State<_NameCard> {
  late final _name = TextEditingController(text: AdminScope.read(context).displayName ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    return AdminCard(
      title: 'Display name',
      child: Row(children: [
        Expanded(child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name'))),
        const SizedBox(width: 14),
        FilledButton(
          onPressed: admin.busy
              ? null
              : () async {
                  final error = await admin.changeDisplayName(_name.text);
                  if (context.mounted) showAdminSnack(context, error ?? 'Name saved', error: error != null);
                },
          child: const Text('Save'),
        ),
      ]),
    );
  }
}

class _UsernameCard extends StatefulWidget {
  const _UsernameCard();

  @override
  State<_UsernameCard> createState() => _UsernameCardState();
}

class _UsernameCardState extends State<_UsernameCard> {
  final _username = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    return AdminCard(
      title: 'Change username',
      subtitle: 'You sign in with this username. Current: ${admin.username}',
      child: Row(children: [
        Expanded(
          child: TextField(controller: _username, decoration: const InputDecoration(labelText: 'New username')),
        ),
        const SizedBox(width: 14),
        FilledButton(
          onPressed: admin.busy
              ? null
              : () async {
                  final error = await admin.changeUsername(_username.text);
                  if (!context.mounted) return;
                  showAdminSnack(context, error ?? 'Username changed', error: error != null);
                  if (error == null) _username.clear();
                },
          child: const Text('Change'),
        ),
      ]),
    );
  }
}

/// Current + new password (used on the profile page and on first sign-in).
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final admin = AdminScope.read(context);
    if (_next.text.length < 8) return setState(() => _error = 'Use at least 8 characters for the new password.');
    if (_next.text != _confirm.text) return setState(() => _error = 'The new passwords do not match.');
    if (_next.text == _current.text) return setState(() => _error = 'Choose a password different from the current one.');
    setState(() => _error = null);
    final error = await admin.changePassword(_current.text, _next.text);
    if (!mounted) return;
    if (error != null) return setState(() => _error = error);
    _current.clear();
    _next.clear();
    _confirm.clear();
    showAdminSnack(context, 'Password changed');
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
      const SizedBox(height: 12),
      TextField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'New password (8+ characters)')),
      const SizedBox(height: 12),
      TextField(
        controller: _confirm,
        obscureText: true,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(labelText: 'Re-enter new password'),
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(_error!, style: const TextStyle(color: AdminColors.danger)),
      ],
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(onPressed: admin.busy ? null : _save, child: const Text('Change password')),
      ),
    ]);
  }
}

/// Shown after signing in with the starting password.
class ForcePasswordChangePage extends StatelessWidget {
  const ForcePasswordChangePage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 460,
            child: AdminCard(
              title: 'Set a new password',
              subtitle: 'You signed in with the starting password. Choose your own password to continue.',
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const ChangePasswordForm(),
                const SizedBox(height: 8),
                TextButton(onPressed: admin.signOut, child: const Text('Sign out')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
