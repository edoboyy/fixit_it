import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/safe_dropdown.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleSuspend(UserModel user) async {
    final currentAdminId = context.read<AuthProvider>().currentUser?.id;
    if (user.id == currentAdminId) {
      Helpers.showSnackBar(
        context,
        'You cannot suspend your own admin account.',
        isError: true,
      );
      return;
    }

    final suspending = !user.isSuspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suspending ? 'Suspend user?' : 'Restore user?'),
        content: Text(
          suspending
              ? 'Suspend ${user.name}? They will not be able to sign in.'
              : 'Restore access for ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(suspending ? 'Suspend' : 'Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context
        .read<AdminProvider>()
        .setUserSuspended(user.id, suspending);

    if (!mounted) return;
    Helpers.showSnackBar(
      context,
      success
          ? (suspending ? 'User suspended' : 'User restored')
          : (context.read<AdminProvider>().errorMessage ?? 'Action failed'),
      isError: !success,
    );
  }

  Future<void> _openCredentials(UserModel user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditCredentialsSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final users = admin.manageableUsers.where((u) {
      if (_roleFilter != 'all' && u.role.value != _roleFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.phone?.toLowerCase().contains(q) ?? false) ||
          u.role.value.contains(q) ||
          (u.password?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        actions: const [LogoutIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadUsers(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search name, email, phone, password...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _query = value.trim()),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _roleFilter == 'all',
                          onTap: () => setState(() => _roleFilter = 'all'),
                        ),
                        _FilterChip(
                          label: 'Customers',
                          selected: _roleFilter == 'customer',
                          onTap: () =>
                              setState(() => _roleFilter = 'customer'),
                        ),
                        _FilterChip(
                          label: 'Artisans',
                          selected: _roleFilter == 'artisan',
                          onTap: () =>
                              setState(() => _roleFilter = 'artisan'),
                        ),
                        _FilterChip(
                          label: 'Admins',
                          selected: _roleFilter == 'admin',
                          onTap: () => setState(() => _roleFilter = 'admin'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${users.length} account(s) · tap to view / edit credentials',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: admin.isLoading && admin.users.isEmpty
                  ? const LoadingWidget(message: 'Loading accounts...')
                  : users.isEmpty
                      ? ListView(
                          children: const [
                            EmptyStateWidget(
                              title: 'No accounts found',
                              message: 'Try a different search or filter.',
                              icon: Icons.people_outline,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openCredentials(user),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ProfileAvatar(
                                        name: user.name,
                                        photoUrl: user.photoUrl,
                                        radius: 24,
                                        showRing: false,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                _RoleBadge(role: user.role),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            _CredentialLine(
                                              icon: Icons.email_outlined,
                                              value: user.email,
                                            ),
                                            _CredentialLine(
                                              icon: Icons.phone_outlined,
                                              value: user.phone?.isNotEmpty ==
                                                      true
                                                  ? user.phone!
                                                  : 'No phone',
                                            ),
                                            _CredentialLine(
                                              icon: Icons.lock_outline,
                                              value: user.password
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? user.password!
                                                  : 'Password not stored yet',
                                              obscure: user.password
                                                      ?.isNotEmpty ==
                                                  true,
                                            ),
                                            if (user.isSuspended)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  'Suspended',
                                                  style: TextStyle(
                                                    color: AppConstants
                                                        .accentRed,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit credentials',
                                            onPressed: () =>
                                                _openCredentials(user),
                                            icon: const Icon(Icons.edit_outlined),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                _toggleSuspend(user),
                                            child: Text(
                                              user.isSuspended
                                                  ? 'Restore'
                                                  : 'Suspend',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: user.isSuspended
                                                    ? AppConstants.primaryGreen
                                                    : AppConstants.accentRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppConstants.primaryGreen.withValues(alpha: 0.2),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.customer => Colors.blue,
      UserRole.artisan => AppConstants.primaryGreen,
      UserRole.admin => AppConstants.accentRed,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CredentialLine extends StatefulWidget {
  const _CredentialLine({
    required this.icon,
    required this.value,
    this.obscure = false,
  });

  final IconData icon;
  final String value;
  final bool obscure;

  @override
  State<_CredentialLine> createState() => _CredentialLineState();
}

class _CredentialLineState extends State<_CredentialLine> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final show = !widget.obscure || _visible;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(widget.icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              show ? widget.value : '••••••••',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.obscure)
            InkWell(
              onTap: () => setState(() => _visible = !_visible),
              child: Icon(
                _visible ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Copy',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.value));
              if (!context.mounted) return;
              Helpers.showSnackBar(context, 'Copied', isSuccess: true);
            },
            icon: Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _EditCredentialsSheet extends StatefulWidget {
  const _EditCredentialsSheet({required this.user});

  final UserModel user;

  @override
  State<_EditCredentialsSheet> createState() => _EditCredentialsSheetState();
}

class _EditCredentialsSheetState extends State<_EditCredentialsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _passwordController;
  late UserRole _role;
  late bool _isSuspended;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _locationController = TextEditingController(text: user.location ?? '');
    _passwordController = TextEditingController(text: user.password ?? '');
    _role = user.role;
    _isSuspended = user.isSuspended;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentAdminId = context.read<AuthProvider>().currentUser?.id;
    if (widget.user.id == currentAdminId && _isSuspended) {
      Helpers.showSnackBar(
        context,
        'You cannot suspend your own admin account.',
        isError: true,
      );
      return;
    }

    final password = _passwordController.text.trim();
    final success =
        await context.read<AdminProvider>().updateUserCredentials(
              userId: widget.user.id,
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              location: _locationController.text.trim(),
              role: _role,
              password: password.isEmpty ? null : password,
              isSuspended: _isSuspended,
            );

    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(
        context,
        'Credentials updated for ${_nameController.text.trim()}',
        isSuccess: true,
      );
      Navigator.pop(context);
    } else {
      Helpers.showSnackBar(
        context,
        context.read<AdminProvider>().errorMessage ?? 'Update failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Account credentials',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${widget.user.id}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Full name / username',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Phone',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Location',
                controller: _locationController,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              SafeDropdown<String>(
                label: 'Role',
                value: _role.value,
                items: UserRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role.value,
                        child: Text(role.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _role = UserRole.fromString(value));
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  return Validators.password(v);
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Leave blank to keep current Auth password sync',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Suspended'),
                subtitle: const Text('Blocked users cannot sign in'),
                value: _isSuspended,
                activeTrackColor: AppConstants.accentRed.withValues(alpha: 0.5),
                onChanged: (value) => setState(() => _isSuspended = value),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Save credentials',
                icon: Icons.save_outlined,
                isLoading: admin.isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
