import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/artisan_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/artisan_card.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final artisanProvider = context.read<ArtisanProvider>();
      _locationController.text = artisanProvider.selectedLocation ?? '';
      artisanProvider.loadArtisans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _applyLocation(String value) {
    final artisanProvider = context.read<ArtisanProvider>();
    artisanProvider.filter(location: value.trim());
    setState(() {});
  }

  void _openFilters() {
    final artisanProvider = context.read<ArtisanProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: artisanProvider.selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...AppConstants.serviceCategories.map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(AppConstants.professionLabel(c)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  artisanProvider.filter(category: value ?? '');
                  Navigator.pop(context);
                  artisanProvider.loadArtisans();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: artisanProvider.selectedLocation != null &&
                        AppConstants.ghanaLocations
                            .contains(artisanProvider.selectedLocation)
                    ? artisanProvider.selectedLocation
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All locations'),
                  ),
                  ...AppConstants.ghanaLocations.map(
                    (location) => DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    ),
                  ),
                ],
                onChanged: (value) {
                  _locationController.text = value ?? '';
                  artisanProvider.filter(location: value ?? '');
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Available only'),
                value: artisanProvider.availableOnly ?? false,
                onChanged: (value) {
                  artisanProvider.filter(availableOnly: value);
                  Navigator.pop(context);
                  artisanProvider.loadArtisans();
                },
              ),
              SwitchListTile(
                title: const Text('Sort by rating'),
                value: artisanProvider.sortByRating,
                onChanged: (value) {
                  artisanProvider.setSortByRating(value);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  artisanProvider.clearFilters();
                  _searchController.clear();
                  _locationController.clear();
                  Navigator.pop(context);
                  artisanProvider.loadArtisans();
                  setState(() {});
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final artisanProvider = context.watch<ArtisanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artisans, skills, profession...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          artisanProvider.search('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                artisanProvider.search(value);
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: _locationController.text),
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return AppConstants.ghanaLocations.take(10);
                }
                return AppConstants.ghanaLocations.where(
                  (location) => location.toLowerCase().contains(query),
                );
              },
              onSelected: (selection) {
                _locationController.text = selection;
                _applyLocation(selection);
              },
              fieldViewBuilder: (
                context,
                textController,
                focusNode,
                onFieldSubmitted,
              ) {
                if (_locationController.text.isNotEmpty &&
                    textController.text.isEmpty) {
                  textController.text = _locationController.text;
                }
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Filter by location (e.g. Accra, Kumasi)',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textController.clear();
                              _locationController.clear();
                              _applyLocation('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _locationController.text = value;
                    _applyLocation(value);
                  },
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
            ),
          ),
          if (artisanProvider.selectedLocation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.place, size: 16),
                  label: Text('Near ${artisanProvider.selectedLocation}'),
                  onDeleted: () {
                    _locationController.clear();
                    _applyLocation('');
                  },
                ),
              ),
            ),
          Expanded(
            child: artisanProvider.isLoading
                ? const LoadingWidget(message: 'Searching...')
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: artisanProvider.artisans.isEmpty
                        ? EmptyStateWidget(
                            key: const ValueKey('empty'),
                            title: 'No artisans found',
                            message:
                                'Try a different location, search, or category.',
                            icon: Icons.search_off_outlined,
                            actionLabel: 'Clear filters',
                            onAction: () {
                              _searchController.clear();
                              _locationController.clear();
                              artisanProvider.clearFilters();
                              setState(() {});
                            },
                          )
                        : ListView.separated(
                            key: const ValueKey('results'),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: artisanProvider.artisans.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final artisan = artisanProvider.artisans[index];
                              return ArtisanCard(
                                artisan: artisan,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.customerArtisanProfile,
                                    arguments: artisan,
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
    );
  }
}
