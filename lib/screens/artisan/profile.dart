import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/artisan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/artisan_bottom_nav.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/location_autocomplete_field.dart';
import '../../widgets/logout_icon_button.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/safe_dropdown.dart';

class ArtisanProfileScreen extends StatefulWidget {
  const ArtisanProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  final _pricingController = TextEditingController();
  final _locationController = TextEditingController();
  List<String> _skills = [];
  String? _selectedCategory;
  String? _skillToAdd;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _pricingController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    await context.read<ArtisanProvider>().loadCurrentArtisan(userId);
    if (!mounted) return;
    final artisan = context.read<ArtisanProvider>().currentArtisan;
    if (artisan != null && mounted) {
      final category = AppConstants.normalizeCategory(artisan.category);
      setState(() {
        _pricingController.text = artisan.hourlyRate.toStringAsFixed(0);
        _locationController.text = artisan.location ?? '';
        _isAvailable = artisan.isAvailable;
        _selectedCategory = category;
        final allowed = category == null
            ? const <String>[]
            : AppConstants.skillsForCategory(category);
        _skills = artisan.skills.where(allowed.contains).toList();
        _skillToAdd = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final artisanProvider = context.read<ArtisanProvider>();
    final user = authProvider.currentUser;
    final artisan = artisanProvider.currentArtisan;

    if (user == null || artisan == null) return;

    if (_selectedCategory == null) {
      Helpers.showSnackBar(
        context,
        'Please select a skill category',
        isError: true,
      );
      return;
    }

    final rate = double.tryParse(_pricingController.text) ?? artisan.hourlyRate;

    final updated = artisan.copyWith(
      name: user.name,
      email: user.email,
      phone: user.phone,
      category: _selectedCategory!,
      hourlyRate: rate,
      skills: _skills,
      isAvailable: _isAvailable,
      location: _locationController.text.trim(),
    );

    final success = await artisanProvider.updateArtisanProfile(updated);

    if (!mounted) return;

    if (success) {
      await authProvider.updateProfile(
        user.copyWith(location: _locationController.text.trim()),
      );
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Profile updated');
    } else if (artisanProvider.errorMessage != null) {
      Helpers.showSnackBar(
        context,
        artisanProvider.errorMessage!,
        isError: true,
      );
    }
  }

  void _addSkill() {
    final skill = _skillToAdd;
    if (skill == null || skill.isEmpty || _skills.contains(skill)) return;
    setState(() {
      _skills = [..._skills, skill];
      _skillToAdd = null;
    });
  }

  Future<void> _logout() => Helpers.confirmAndLogout(context);

  List<String> get _availableSkills {
    final category = _selectedCategory;
    if (category == null) return const [];
    return AppConstants.skillsForCategory(category)
        .where((skill) => !_skills.contains(skill))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final artisanProvider = context.watch<ArtisanProvider>();
    final user = authProvider.currentUser;
    final artisan = artisanProvider.currentArtisan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [LogoutIconButton()],
      ),
      body: artisanProvider.isLoading && artisan == null
          ? const LoadingWidget(message: 'Loading profile...')
          : user == null || artisan == null
              ? Center(
                  child: Text(
                    'Artisan profile not found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatar(
                          name: artisan.name,
                          photoUrl: artisan.photoUrl,
                          radius: 52,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        artisan.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 22),
                      ),
                      Text(
                        _selectedCategory != null
                            ? AppConstants.professionLabel(_selectedCategory!)
                            : (artisan.category.isEmpty
                                ? 'No category set'
                                : artisan.category),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.howToUse),
                        icon: const Icon(Icons.help_outline_rounded),
                        label: const Text('How to use Fixit GH'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available for bookings'),
                        subtitle: const Text('Toggle your availability'),
                        value: _isAvailable,
                        activeTrackColor: AppConstants.primaryGreen,
                        onChanged: (value) =>
                            setState(() => _isAvailable = value),
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
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _skillToAdd = null;
                            if (value != null) {
                              final allowed =
                                  AppConstants.skillsForCategory(value);
                              _skills =
                                  _skills.where(allowed.contains).toList();
                            } else {
                              _skills = [];
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      LocationAutocompleteField(
                        controller: _locationController,
                        label: 'Service location',
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Hourly Rate (GHS)',
                        controller: _pricingController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Skills',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_skills.isEmpty)
                        Text(
                          'No skills added yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  onDeleted: () => setState(
                                    () => _skills = _skills
                                        .where((s) => s != skill)
                                        .toList(),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SafeDropdown<String>(
                              label: 'Add skill from category',
                              hint: _selectedCategory == null
                                  ? 'Select a category first'
                                  : 'Choose a skill',
                              value: _skillToAdd,
                              items: _availableSkills
                                  .map(
                                    (skill) => DropdownMenuItem(
                                      value: skill,
                                      child: Text(skill),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _selectedCategory == null
                                  ? null
                                  : (value) =>
                                      setState(() => _skillToAdd = value),
                            ),
                          ),
                          IconButton(
                            onPressed: _addSkill,
                            icon: const Icon(Icons.add_circle),
                            color: AppConstants.primaryGreen,
                          ),
                        ],
                      ),
                      if (artisan.experience != null) ...[
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.work_history),
                          title: const Text('Experience'),
                          subtitle: Text(artisan.experience!),
                        ),
                      ],
                      if (artisan.nationalId != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('National ID'),
                          subtitle: Text(
                            artisan.nationalId!.contains('|')
                                ? artisan.nationalId!.replaceFirst('|', ' · ')
                                : artisan.nationalId!,
                          ),
                        ),
                      ],
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          final brightness =
                              Theme.of(context).brightness;
                          final isDark = brightness == Brightness.dark;
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: AppConstants.primaryGreen,
                            ),
                            title: const Text('Dark mode'),
                            subtitle:
                                const Text('Optional appearance setting'),
                            value: isDark,
                            onChanged: themeProvider.toggleDark,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Save Profile',
                        icon: Icons.save,
                        isLoading: artisanProvider.isLoading,
                        onPressed: _saveProfile,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Logout',
                        icon: Icons.logout,
                        variant: CustomButtonVariant.text,
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: widget.embedded
          ? null
          : const ArtisanBottomNav(currentIndex: 2),
    );
  }
}
