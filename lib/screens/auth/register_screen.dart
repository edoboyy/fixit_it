import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/post_login_navigation.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_autocomplete_field.dart';
import '../../widgets/safe_dropdown.dart';
import '../../widgets/success_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialRole = UserRole.customer,
  });

  final UserRole initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _experienceController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _locationController = TextEditingController();

  late UserRole _selectedRole;
  String? _selectedCategory;
  String? _selectedIdType;
  Uint8List? _certificateBytes;
  String? _certificateFileName;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == UserRole.admin
        ? UserRole.customer
        : widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _experienceController.dispose();
    _nationalIdController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _certificateBytes = file.bytes;
      _certificateFileName = file.name;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == UserRole.artisan) {
      if (_selectedCategory == null) {
        Helpers.showSnackBar(context, 'Please select a skill category',
            isError: true);
        return;
      }
      if (_selectedIdType == null) {
        Helpers.showSnackBar(context, 'Please select an ID type', isError: true);
        return;
      }
      if (_certificateBytes == null) {
        Helpers.showSnackBar(
          context,
          'Please upload your certificate',
          isError: true,
        );
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      profession: _selectedRole == UserRole.artisan ? _selectedCategory : null,
      experience: _selectedRole == UserRole.artisan
          ? _experienceController.text.trim()
          : null,
      nationalId: _selectedRole == UserRole.artisan
          ? _nationalIdController.text.trim()
          : null,
      idType: _selectedRole == UserRole.artisan ? _selectedIdType : null,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      certificateBytes: _certificateBytes,
      certificateFileName: _certificateFileName,
    );

    if (!mounted) return;

    TextInput.finishAutofillContext(shouldSave: false);

    if (success) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      final roleLabel = switch (authProvider.currentUser?.role) {
        UserRole.artisan => 'artisan',
        UserRole.admin => 'admin',
        _ => 'customer',
      };
      await SuccessDialog.show(
        context,
        title: 'Welcome to Fixit GH',
        message: 'Your $roleLabel account was created successfully.',
      );
      if (!mounted) return;
      await navigateAfterAuth(context);
    } else if (authProvider.errorMessage != null) {
      Helpers.showSnackBar(context, authProvider.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isArtisan = _selectedRole == UserRole.artisan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.login,
              arguments: _selectedRole,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join ${AppConstants.appName}',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Register as a customer or artisan',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                _RoleSelector(
                  selectedRole: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Full Name (Username)',
                  hint: 'Used to sign in as username',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  autofillHints: const [],
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  autofillHints: const [],
                  enableSuggestions: false,
                  autocorrect: false,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  autofillHints: const [],
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                LocationAutocompleteField(
                  controller: _locationController,
                  label: 'Location',
                  required: isArtisan,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  autofillHints: const [],
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  autofillHints: const [],
                  validator: (v) => Validators.confirmPassword(
                    v,
                    _passwordController.text,
                  ),
                ),
                if (isArtisan) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Artisan Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SafeDropdown<String>(
                    label: 'Skill / Profession',
                    hint: 'Select category',
                    prefixIcon: Icons.work_outline,
                    value: _selectedCategory,
                    items: AppConstants.serviceCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              AppConstants.professionLabel(category),
                            ),
                          ),
                        )
                        .toList(),
                    validator: (v) =>
                        Validators.dropdown(v, field: 'skill category'),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Experience',
                    hint: 'e.g. 5 years',
                    controller: _experienceController,
                    prefixIcon: Icons.timeline,
                    validator: (v) =>
                        Validators.required(v, field: 'Experience'),
                  ),
                  const SizedBox(height: 16),
                  SafeDropdown<String>(
                    label: 'National ID Type',
                    hint: 'Select ID type',
                    prefixIcon: Icons.badge_outlined,
                    value: _selectedIdType,
                    items: AppConstants.nationalIdTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    validator: (v) =>
                        Validators.dropdown(v, field: 'ID type'),
                    onChanged: (value) =>
                        setState(() => _selectedIdType = value),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'ID Number',
                    controller: _nationalIdController,
                    prefixIcon: Icons.numbers,
                    autofillHints: const [],
                    validator: Validators.nationalId,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _pickCertificate,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _certificateFileName ?? 'Upload Certificate',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Create Account',
                  icon: Icons.person_add,
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                          arguments: _selectedRole,
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment(
          value: UserRole.customer,
          label: Text('Customer'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment(
          value: UserRole.artisan,
          label: Text('Artisan'),
          icon: Icon(Icons.handyman),
        ),
      ],
      selected: {selectedRole},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
