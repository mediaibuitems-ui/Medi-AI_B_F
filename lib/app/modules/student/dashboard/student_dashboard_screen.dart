import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'student_dashboard_controller.dart';
import '../../../../config/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/appointment.dart';
import '../../../widgets/dashboard_stat_card.dart';
import '../../../widgets/dashboard_quick_action.dart';


class StudentDashboardScreen extends GetView<StudentDashboardController> {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
  // Show loader if the app is working OR if we don't have a valid User ID yet
  bool isMissingId = (controller.currentUser.value?.id ?? "").isEmpty;
  
  if (controller.isLoading.value || isMissingId) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Loading your health data..."),
          ],
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}),
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildStatisticsCards(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildUpcomingAppointments(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.surface),
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text('Student Dashboard'),
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.surface,
      elevation: 0,
      actions: [
        Obx(() {
          return IconButton(
            icon: Badge(
              isLabelVisible: controller.unreadNotifications.value > 0,
              label: Text(controller.unreadNotifications.value.toString()),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Get.toNamed(AppRoutes.notifications),
          );
        }),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Obx(() {
            final user = controller.currentUser.value;
            final profileImage = user?.profileImage;
            final hasImage = profileImage != null && profileImage.trim().isNotEmpty;
            return UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                user?.name ?? 'Student',
                style: AppTheme.dashboardDrawerName,
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: AppTheme.dashboardDrawerEmail,
              ),
              currentAccountPicture: CircleAvatar(
              backgroundColor: AppTheme.surface,
                backgroundImage: hasImage ? NetworkImage(profileImage) : null,
                child: hasImage
                    ? null
                    : const Icon(Icons.school_rounded,
                        size: 32, color: AppTheme.primary),
              ),
            );
          }),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  selected: true,
                  selectedTileColor: AppTheme.primary.withOpacity(0.1),
                  onTap: () => Get.back(),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Book Appointment'),
                  onTap: () {
                    Get.back();
                    controller.goToBookAppointment();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('My Appointments'),
                  onTap: () {
                    Get.back();
                    controller.goToMyAppointments();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.psychology_outlined),
                  title: const Text('AI Symptom Analyzer'),
                  onTap: () {
                    Get.back();
                    controller.goToAIChecker();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_outlined),
                  title: const Text('Medicine Reminders'),
                  onTap: () {
                    Get.back();
                    controller.goToMedicineReminders();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu),
                  title: const Text('Medical History'),
                  onTap: () {
                    Get.back();
                    controller.goToMedicalHistory();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_phone_outlined),
                  title: const Text('Emergency Contacts'),
                  onTap: () {
                    Get.back();
                    controller.goToEmergencyContacts();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  onTap: () {
                    Get.back();
                    controller.goToProfile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Feedback'),
                  onTap: () {
                    Get.back();
                    controller.goToFeedback();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Get.back();
                    controller.goToSettings();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            onTap: controller.logout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Obx(() {
      final user = controller.currentUser.value;
      final profileImage = user?.profileImage;
      final hasImage = profileImage != null && profileImage.trim().isNotEmpty;
      return InkWell(
        onTap: controller.goToProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
                child: Icon(
                Icons.school_rounded,
                size: 132,
                color: AppTheme.surface.withOpacity(0.12),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
                child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.surface.withOpacity(0.18),
                    backgroundImage:
                        hasImage ? NetworkImage(profileImage) : null,
                    child: hasImage
                        ? null
                        : Icon(
                            Icons.school_rounded,
                            size: 32,
                            color: AppTheme.surface,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.getGreeting(),
                          style: AppTheme.dashboardWelcomeGreeting,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Student',
                          style: AppTheme.dashboardWelcomeName,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.department ?? 'BUITEMS Student',
                          style: AppTheme.dashboardWelcomeSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      );
    });
  }

  Widget _buildStatisticsCards() {
    return Obx(() => Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Total Appointments',
                value: controller.totalAppointments.value.toString(),
                icon: Icons.calendar_today,
                color: AppTheme.info,
                onTap: () => Get.toNamed(AppRoutes.myAppointments, arguments: {'filter': 'All'}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Completed',
                value: controller.completedAppointments.value.toString(),
                icon: Icons.check_circle,
                color: AppTheme.success,
                onTap: () => Get.toNamed(AppRoutes.myAppointments, arguments: {'filter': 'Completed'}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardStatCard(
                title: 'Upcoming',
                value: controller.upcomingCount.value.toString(),
                icon: Icons.pending,
                color: AppTheme.warning,
                onTap: () => Get.toNamed(AppRoutes.myAppointments, arguments: {'filter': 'Upcoming'}),
              ),
            ),
          ],
        ));
  }



  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.dashboardSectionTitle,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'Book Appointment',
                    icon: Icons.add_circle,
                    color: AppTheme.info,
                    onTap: controller.goToBookAppointment,
                    index: 0,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'AI Symptom Analyzer',
                    icon: Icons.psychology,
                    color: AppTheme.success,
                    onTap: controller.goToAIChecker,
                    index: 1,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'My Appointments',
                    icon: Icons.list_alt,
                    color: AppTheme.warning,
                    onTap: controller.goToMyAppointments,
                    index: 2,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'Medicine Reminders',
                    icon: Icons.alarm,
                    color: AppTheme.secondary,
                    onTap: controller.goToMedicineReminders,
                    index: 3,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'My Prescriptions',
                    icon: Icons.receipt_long,
                    color: AppTheme.primary,
                    onTap: controller.goToPrescriptionHistory,
                    index: 4,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }



  Widget _buildUpcomingAppointments() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    'Upcoming Appointments',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.dashboardSectionTitle,
                ),
              ),
              if (controller.upcomingAppointments.isNotEmpty)
                TextButton(
                  onPressed: controller.goToMyAppointments,
                    child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Future appointments you can still update or cancel when allowed.',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 12),
            controller.upcomingAppointments.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.upcomingAppointments.length > 3
                      ? 3
                      : controller.upcomingAppointments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final appointment = controller.upcomingAppointments[index];
                    return _buildAppointmentCard(
                      appointment,
                      sectionLabel: 'Upcoming',
                    );
                  },
                ),
        ],
      );
    });
  }



  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 68,
            color: AppTheme.primary.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'No upcoming appointments.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.goToBookAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment, {
    required String sectionLabel,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final statusColor = _getStatusColor(appointment.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.reason,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sectionLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.info,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Status: ${appointment.status}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (controller.canEditAppointment(appointment))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditDialog(appointment),
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.blue),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _confirmCancel(appointment),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.cancel,
                                  size: 20, color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(appointment.appointmentDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(appointment.appointmentDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Confirmed') return AppTheme.success;
    if (status == 'Pending') return AppTheme.warning;
    if (status == 'Cancelled') return AppTheme.error;
    if (status == 'Completed') return AppTheme.info;
    return AppTheme.textSecondary;
  }

  void _confirmCancel(Appointment appointment) {
    Get.defaultDialog(
      title: 'Cancel Appointment',
      middleText: 'Are you sure you want to cancel this appointment?',
      textConfirm: 'Yes',
      textCancel: 'No',
      confirmTextColor: AppTheme.surface,
      onConfirm: () {
        Get.back();
        controller.cancelAppointment(appointment.id);
      },
    );
  }

  void _showEditDialog(Appointment appointment) {
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(appointment.appointmentDate));
    final timeController = TextEditingController(
        text: DateFormat('HH:mm').format(appointment.appointmentDate));
    final symptomsController =
        TextEditingController(text: appointment.symptoms);
    final notesController =
        TextEditingController(text: appointment.notes ?? '');

    DateTime selectedDate = appointment.appointmentDate;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                    labelText: 'Date',
                    suffixIcon: const Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: Get.context!,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                    labelText: 'Time',
                    suffixIcon: const Icon(Icons.access_time)),
                readOnly: true,
                onTap: () async {
                  final currentT =
                      TimeOfDay.fromDateTime(appointment.appointmentDate);
                  final time = await showTimePicker(
                      context: Get.context!, initialTime: currentT);
                  if (time != null) {
                    final dt = DateTime(0, 0, 0, time.hour, time.minute);
                    timeController.text = DateFormat('HH:mm').format(dt);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: symptomsController,
                  decoration: const InputDecoration(labelText: 'Symptoms'),
                  maxLines: 2),
              const SizedBox(height: 16),
              TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateAppointment(
                appointment.id,
                appointment.doctorId,
                selectedDate,
                timeController.text,
                symptomsController.text,
                notesController.text,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

