import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import 'book_appointment_controller.dart';

export 'book_appointment_binding.dart';

class BookAppointmentScreen extends GetView<BookAppointmentController> {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.doctors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Specialization Selection
              if (controller.specializations.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter by specialization',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: controller.selectedSpecialization.value,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'All specializations',
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('All specializations'),
                            ),
                            ...controller.specializations.map((spec) {
                              return DropdownMenuItem(
                                value: spec,
                                child: Text(spec),
                              );
                            }),
                          ],
                          onChanged: controller.onSpecializationChanged,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Doctor Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select doctor',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: controller.selectedDoctorId.value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a doctor',
                        ),
                        items: controller.filteredDoctors.map((doctor) {
                          final name =
                              doctor['user']?['fullName'] ?? 'Unknown doctor';
                          final spec = doctor['specialization'] ?? '';

                          return DropdownMenuItem(
                            value: doctor['id'].toString(),
                            child: Text(
                              '$name - $spec',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: controller.onDoctorChanged,
                        validator: (value) =>
                            value == null ? 'Please select a doctor' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select date',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            controller.onDateSelected(picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          controller.selectedDate.value == null
                              ? 'Select date'
                              : DateFormat('MMM dd, yyyy')
                                  .format(controller.selectedDate.value!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time Slot Selection
              if (controller.selectedDate.value != null &&
                  controller.selectedDoctorId.value != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select time slot',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (controller.isLoadingSlots.value)
                          const Center(child: CircularProgressIndicator())
                        else if (controller.availableSlots.isEmpty)
                          const Text(
                            'No available slots on this date',
                            style: TextStyle(color: Colors.red),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: controller.availableSlots.map((slot) {
                              final time = slot['time'];
                              final isAvailable = slot['available'] == true;
                              final isSelected =
                                  controller.selectedSlot.value == slot;

                              return FilterChip(
                                label: Text(time),
                                selected: isSelected,
                                onSelected: isAvailable
                                    ? (selected) {
                                        controller.selectedSlot.value =
                                            selected ? slot : null;
                                      }
                                    : null,
                                selectedColor: AppTheme.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isAvailable
                                          ? Colors.black
                                          : Colors.grey),
                                ),
                                backgroundColor: isAvailable
                                    ? Colors.white
                                    : Colors.grey[200],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Symptoms & Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.symptomsController,
                        decoration: InputDecoration(
                          labelText: 'Symptoms',
                          border: OutlineInputBorder(),
                          hintText: 'Describe your symptoms',
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please describe your symptoms'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.notesController,
                        decoration: InputDecoration(
                          labelText: 'Additional notes',
                          border: OutlineInputBorder(),
                          hintText: 'Any specific requirements',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Book appointment',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
