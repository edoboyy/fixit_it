import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../models/artisan_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';

class AdminArtisansScreen extends StatefulWidget {
  const AdminArtisansScreen({super.key});

  @override
  State<AdminArtisansScreen> createState() => _AdminArtisansScreenState();
}

class _AdminArtisansScreenState extends State<AdminArtisansScreen> {
  bool _pendingOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadArtisans();
    });
  }

  Future<void> _toggleVerify(ArtisanModel artisan) async {
    final verifying = !artisan.isVerified;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(verifying ? 'Verify artisan?' : 'Remove verification?'),
        content: Text(
          verifying
              ? 'Mark ${artisan.name} as a verified artisan?'
              : 'Remove verified status from ${artisan.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(verifying ? 'Verify' : 'Unverify'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context
        .read<AdminProvider>()
        .setArtisanVerified(artisan.id, verifying);

    if (!mounted) return;
    Helpers.showSnackBar(
      context,
      success
          ? (verifying ? 'Artisan verified' : 'Verification removed')
          : (context.read<AdminProvider>().errorMessage ?? 'Action failed'),
      isError: !success,
    );
  }

  Future<void> _showCertificate(ArtisanModel artisan) async {
    final url = artisan.certificateUrl;
    if (url == null || url.isEmpty) {
      Helpers.showSnackBar(context, 'No certificate uploaded', isError: true);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(context, 'Certificate URL copied');
              }
            },
            child: const Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final artisans = admin.artisans
        .where((a) => !_pendingOnly || !a.isVerified)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Artisans'),
        actions: [
          FilterChip(
            label: const Text('Pending'),
            selected: _pendingOnly,
            onSelected: (value) => setState(() => _pendingOnly = value),
            selectedColor: AppConstants.accentGold.withValues(alpha: 0.4),
          ),
          const LogoutIconButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadArtisans(),
        child: admin.isLoading && admin.artisans.isEmpty
            ? const LoadingWidget(message: 'Loading artisans...')
            : artisans.isEmpty
                ? ListView(
                    children: const [
                      EmptyStateWidget(
                        title: 'No artisans found',
                        message: 'Pending artisans will appear here for verification.',
                        icon: Icons.handyman_outlined,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: artisans.length,
                    itemBuilder: (context, index) {
                      final artisan = artisans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artisan.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${AppConstants.professionLabel(artisan.category)} · '
                                          '${artisan.email}',
                                        ),
                                        Text(
                                          [
                                            if (artisan.phone != null)
                                              artisan.phone!,
                                            if (artisan.location != null &&
                                                artisan.location!.isNotEmpty)
                                              artisan.location!,
                                            if (artisan.nationalId != null &&
                                                artisan.nationalId!.isNotEmpty)
                                              artisan.nationalId!
                                                  .replaceFirst('|', ' · '),
                                          ].join(' · '),
                                        ),
                                        Text(
                                          artisan.isVerified
                                              ? 'Verified'
                                              : 'Not verified',
                                          style: TextStyle(
                                            color: artisan.isVerified
                                                ? Colors.green.shade700
                                                : Colors.orange.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    artisan.isVerified
                                        ? Icons.verified
                                        : Icons.hourglass_empty,
                                    color: artisan.isVerified
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showCertificate(artisan),
                                    icon: const Icon(Icons.description_outlined),
                                    label: const Text('Certificate'),
                                  ),
                                  const Spacer(),
                                  FilledButton(
                                    onPressed: () => _toggleVerify(artisan),
                                    child: Text(
                                      artisan.isVerified
                                          ? 'Unverify'
                                          : 'Verify',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
    );
  }
}
