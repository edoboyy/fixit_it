import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/artisan_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_autocomplete_field.dart';
import '../../widgets/success_dialog.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.artisan});

  final ArtisanModel artisan;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      Helpers.showSnackBar(
        context,
        'Please select date and time',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final customerId = authProvider.currentUser?.id;

    if (customerId == null) {
      Helpers.showSnackBar(context, 'Please sign in to book', isError: true);
      return;
    }

    final scheduledDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final artisanId = widget.artisan.userId.isNotEmpty
        ? widget.artisan.userId
        : widget.artisan.id;

    final booking = BookingModel(
      id: '',
      customerId: customerId,
      artisanId: artisanId,
      serviceCategory: widget.artisan.category,
      description: _descriptionController.text.trim(),
      status: BookingStatus.awaitingApproval,
      scheduledDate: scheduledDate,
      location: _addressController.text.trim(),
      estimatedPrice: widget.artisan.hourlyRate,
    );

    final success = await bookingProvider.createBooking(booking);

    if (!mounted) return;

    if (success) {
      await SuccessDialog.show(
        context,
        title: 'Booking submitted',
        message:
            'Your request is awaiting admin approval. '
            'Once approved, the artisan will be notified to start work.',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else if (bookingProvider.errorMessage != null) {
      Helpers.showSnackBar(
        context,
        bookingProvider.errorMessage!,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final artisan = widget.artisan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(artisan.name.isNotEmpty ? artisan.name[0] : '?'),
                ),
                title: Text(artisan.name),
                subtitle: Text(artisan.category),
                trailing: Text(
                  'GHS ${artisan.hourlyRate.toStringAsFixed(0)}/hr',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select a date',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select a time',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              LocationAutocompleteField(
                controller: _addressController,
                label: 'Service location',
                hint: 'Search area or city in Ghana',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                hint: 'Describe the work needed',
                controller: _descriptionController,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (v) => Validators.required(v, field: 'Description'),
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Submit Booking',
                icon: Icons.check_circle_outline,
                isLoading: bookingProvider.isLoading,
                onPressed: _submitBooking,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
