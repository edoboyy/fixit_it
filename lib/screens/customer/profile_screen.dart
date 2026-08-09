import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/location_autocomplete_field.dart';
import '../../widgets/logout_icon_button.dart';
import '../../widgets/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfile(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final locationController = TextEditingController(text: user.location ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Name',
                  controller: nameController,
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Phone',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                LocationAutocompleteField(
                  controller: locationController,
                  label: 'Location',
                  required: false,
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      label: 'Save Changes',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final updated = user.copyWith(
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          location: locationController.text.trim(),
                        );

                        final success =
                            await authProvider.updateProfile(updated);

                        if (!sheetContext.mounted) return;

                        if (success) {
                          Navigator.pop(sheetContext);
                          Helpers.showSnackBar(
                            context,
                            'Profile updated',
                          );
                        } else if (authProvider.errorMessage != null) {
                          Helpers.showSnackBar(
                            context,
                            authProvider.errorMessage!,
                            isError: true,
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [LogoutIconButton()],
      ),
      body: user == null
          ? const EmptyStateWidget(
              title: 'No profile found',
              message: 'Please sign in again to view your profile.',
              icon: Icons.person_off_outlined,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ProfileAvatar(
                    name: user.name,
                    photoUrl: user.photoUrl,
                    radius: 52,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.howToUse),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text('How to use Fixit GH'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      user.role.name[0].toUpperCase() +
                          user.role.name.substring(1),
                    ),
                    backgroundColor:
                        AppConstants.primaryGreen.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 32),
                  _ProfileTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user.phone ?? 'Not set',
                  ),
                  _ProfileTile(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: user.location ?? 'Not set',
                  ),
                  const SizedBox(height: 8),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final isDark =
                          themeProvider.themeMode == ThemeMode.dark ||
                              (themeProvider.themeMode == ThemeMode.system &&
                                  MediaQuery.platformBrightnessOf(context) ==
                                      Brightness.dark);
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: AppConstants.primaryGreen,
                        ),
                        title: const Text('Dark mode'),
                        subtitle: const Text('Optional appearance setting'),
                        value: isDark,
                        onChanged: themeProvider.toggleDark,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    variant: CustomButtonVariant.outlined,
                    onPressed: () => _showEditProfile(context, user),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'Logout',
                    icon: Icons.logout,
                    variant: CustomButtonVariant.text,
                    onPressed: () => Helpers.confirmAndLogout(context),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppConstants.primaryGreen),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
