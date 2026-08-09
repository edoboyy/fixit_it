import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/booking_workflow.dart';
import '../models/booking_model.dart';

class BookingStatusTracker extends StatelessWidget {
  const BookingStatusTracker({
    super.key,
    required this.status,
    this.compact = false,
  });

  final BookingStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (status == BookingStatus.cancelled) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text('Cancelled'),
          backgroundColor: Color(0xFFFFEBEE),
        ),
      );
    }

    final currentIndex = BookingWorkflow.stepIndex(status);
    final steps = BookingWorkflow.lifecycle;

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;

        return SizedBox(
          width: maxWidth,
          height: 4,
          child: Row(
            children: List.generate(steps.length, (index) {
              final isDone = index <= currentIndex;
              final isCurrent = index == currentIndex;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < steps.length - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppConstants.primaryGreen
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppConstants.primaryGreen
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );

    if (compact) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isDone = index <= currentIndex;
            return Text(
              BookingWorkflow.label(step),
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    index == currentIndex ? FontWeight.w600 : FontWeight.normal,
                color:
                    isDone ? AppConstants.primaryGreen : Colors.grey.shade500,
              ),
            );
          }),
        ),
      ],
    );
  }
}
