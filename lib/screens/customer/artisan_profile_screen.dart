import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/firestore_service.dart';
import '../../models/artisan_model.dart';
import '../../models/review_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class CustomerArtisanProfileScreen extends StatefulWidget {
  const CustomerArtisanProfileScreen({
    super.key,
    required this.artisan,
  });

  final ArtisanModel artisan;

  @override
  State<CustomerArtisanProfileScreen> createState() =>
      _CustomerArtisanProfileScreenState();
}

class _CustomerArtisanProfileScreenState
    extends State<CustomerArtisanProfileScreen> {
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await FirestoreService().getReviewsByArtisan(
        widget.artisan.id,
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artisan = widget.artisan;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppConstants.primaryGreen.withValues(alpha: 0.15),
                child: Center(
                  child: Hero(
                    tag: 'artisan-avatar-${artisan.id}',
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor:
                          AppConstants.primaryGreen.withValues(alpha: 0.2),
                      backgroundImage: artisan.photoUrl != null
                          ? NetworkImage(artisan.photoUrl!)
                          : null,
                      child: artisan.photoUrl == null
                          ? Text(
                              artisan.name.isNotEmpty
                                  ? artisan.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryGreen,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artisan.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 24,
                          ),
                        ),
                      ),
                      if (artisan.isVerified)
                        const Icon(
                          Icons.verified,
                          color: AppConstants.primaryGreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artisan.category,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppConstants.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppConstants.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        '${artisan.rating.toStringAsFixed(1)} (${artisan.reviewCount} reviews)',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoTile(
                    icon: Icons.payments_outlined,
                    label: 'Price',
                    value: 'GHS ${artisan.hourlyRate.toStringAsFixed(0)}/hour',
                  ),
                  if (artisan.experience != null)
                    _InfoTile(
                      icon: Icons.work_history,
                      label: 'Experience',
                      value: artisan.experience!,
                    ),
                  if (artisan.location != null)
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: artisan.location!,
                    ),
                  if (artisan.bio != null) ...[
                    const SizedBox(height: 16),
                    Text('About', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(artisan.bio!, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 24),
                  Text('Reviews', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_isLoadingReviews)
                    const LoadingWidget(message: 'Loading reviews...')
                  else if (_reviews.isEmpty)
                    Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    ..._reviews.map(
                      (review) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(review.customerName ?? 'Customer'),
                              const Spacer(),
                              const Icon(Icons.star, size: 16, color: AppConstants.accentGold),
                              Text(' ${review.rating.toStringAsFixed(1)}'),
                            ],
                          ),
                          subtitle: review.comment != null
                              ? Text(review.comment!)
                              : null,
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            label: 'Book Now',
            icon: Icons.calendar_today,
            onPressed: artisan.isAvailable
                ? () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.customerBooking,
                      arguments: artisan,
                    );
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.primaryGreen),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
