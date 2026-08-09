import 'package:flutter/material.dart';

/// Dropdown that never crashes on null selection or empty item lists.
///
/// Uses [DropdownButton] (not [DropdownButtonFormField]) because newer Flutter
/// versions throw `Unexpected null value` when FormField value/initialValue is
/// null — which is common before the user picks a category/skill.
class SafeDropdown<T> extends StatelessWidget {
  const SafeDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          hint ?? 'No options available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final itemValues = <T>{};
    for (final item in items) {
      final v = item.value;
      if (v != null) itemValues.add(v);
    }
    final safeValue = (value != null && itemValues.contains(value)) ? value : null;

    return FormField<T>(
      initialValue: safeValue,
      validator: validator,
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: const OutlineInputBorder(),
            errorText: state.errorText,
          ),
          isEmpty: safeValue == null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              isDense: true,
              value: safeValue,
              hint: Text(
                hint ?? 'Select',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              items: items
                  .where((item) => item.value != null)
                  .toList(growable: false),
              onChanged: onChanged == null
                  ? null
                  : (selected) {
                      state.didChange(selected);
                      onChanged!(selected);
                    },
            ),
          ),
        );
      },
    );
  }
}
