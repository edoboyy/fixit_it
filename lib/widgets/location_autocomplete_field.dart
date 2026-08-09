import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/validators.dart';

/// Location field with Ghana place autocomplete suggestions.
class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
    this.label = 'Location',
    this.hint = 'Search area or city in Ghana',
    this.required = true,
    this.onSelected,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final ValueChanged<String>? onSelected;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return AppConstants.ghanaLocations.take(12);
        }
        return AppConstants.ghanaLocations.where(
          (location) => location.toLowerCase().contains(query),
        );
      },
      displayStringForOption: (option) => option,
      onSelected: (selection) {
        widget.controller.text = selection;
        widget.onSelected?.call(selection);
      },
      fieldViewBuilder: (
        context,
        textController,
        focusNode,
        onFieldSubmitted,
      ) {
        return _SyncedLocationField(
          externalController: widget.controller,
          textController: textController,
          focusNode: focusNode,
          onFieldSubmitted: onFieldSubmitted,
          label: widget.label,
          hint: widget.hint,
          required: widget.required,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 20),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyncedLocationField extends StatefulWidget {
  const _SyncedLocationField({
    required this.externalController,
    required this.textController,
    required this.focusNode,
    required this.onFieldSubmitted,
    required this.label,
    required this.hint,
    required this.required,
  });

  final TextEditingController externalController;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;
  final String label;
  final String hint;
  final bool required;

  @override
  State<_SyncedLocationField> createState() => _SyncedLocationFieldState();
}

class _SyncedLocationFieldState extends State<_SyncedLocationField> {
  @override
  void initState() {
    super.initState();
    if (widget.externalController.text.isNotEmpty &&
        widget.textController.text.isEmpty) {
      widget.textController.text = widget.externalController.text;
    }
    widget.textController.addListener(_syncOut);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_syncOut);
    super.dispose();
  }

  void _syncOut() {
    if (widget.externalController.text != widget.textController.text) {
      widget.externalController.text = widget.textController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.textController,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => widget.onFieldSubmitted(),
      validator: widget.required
          ? (v) => Validators.required(v, field: widget.label)
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
    );
  }
}
