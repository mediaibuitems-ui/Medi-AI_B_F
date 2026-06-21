import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_theme.dart';
import '../../../data/models/appointment.dart';
import 'doctor_dashboard_controller.dart';

export 'doctor_dashboard_binding.dart';

class DoctorDashboardScreen extends GetView<DoctorDashboardController> {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.currentUser.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildStatisticsCards(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildTodayAppointments(),
                const SizedBox(height: 24),
                _buildUpcomingAppointments(),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: Image.asset(
            'assets/images/logos/buitems-logo-png_seeklogo-273407.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.menu);
            },
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text('Doctor Dashboard'),
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.surface,
      elevation: 0,
      actions: [
        Obx(() {
          final unreadCount = controller.unreadNotifications.length;
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: controller.viewNotifications,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
            final imageUrl = user?.profileImage;
            final hasValidImageUrl =
              imageUrl != null && imageUrl.trim().isNotEmpty;

            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.textPrimary.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              accountName: Text(
                user?.name ?? 'Doctor',
                style: AppTheme.dashboardDrawerName,
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: AppTheme.dashboardDrawerEmail,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.surface,
                backgroundImage:
                  hasValidImageUrl ? NetworkImage(imageUrl) : null,
                child: hasValidImageUrl
                    ? null
                    : const Icon(Icons.medical_services,
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
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('My Appointments'),
                  onTap: () {
                    Get.back();
                    controller.viewAllAppointments();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Patients'),
                  onTap: () {
                    Get.back();
                    controller.viewPatients();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Set Schedule'),
                  onTap: () {
                    Get.back();
                    controller.viewSchedule();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_busy_outlined),
                  title: const Text('Manage Leaves'),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/doctor/leaves');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  onTap: () {
                    Get.back();
                    controller.viewProfile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Get.back();
                    controller.viewSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: const Text('Booking Settings'),
                  onTap: () {
                    Get.back();
                    controller.viewBookingSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Submit Feedback'),
                  onTap: () {
                    Get.back();
                    controller.viewFeedback();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title:
                const Text('Logout', style: TextStyle(color: AppTheme.error)),
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
      final imageUrl = user?.profileImage;
      final hasValidImageUrl = imageUrl != null && imageUrl.trim().isNotEmpty;

      return InkWell(
        onTap: controller.viewProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -18,
                child: Icon(
                  Icons.medical_services,
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
                      backgroundColor: AppTheme.surface.withOpacity(0.2),
                      backgroundImage:
                        hasValidImageUrl ? NetworkImage(imageUrl) : null,
                      child: hasValidImageUrl
                          ? null
                          : const Icon(
                              Icons.medical_services,
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
                            'Dr. ${user?.name ?? 'Doctor'}',
                            style: AppTheme.dashboardWelcomeName,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.department ?? 'Medical Department',
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
              child: _buildStatCard(
                'Total Patients',
                controller.totalPatients.value.toString(),
                Icons.people_outline,
                AppTheme.info,
                () => controller.viewPatients(),
                false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                controller.completedToday.value.toString(),
                Icons.check_circle_outline,
                AppTheme.success,
                () => controller.toggleFilter('completed'),
                controller.activeFilter.value == 'completed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                controller.pendingToday.value.toString(),
                Icons.pending_outlined,
                AppTheme.warning,
                () => controller.toggleFilter('pending'),
                controller.activeFilter.value == 'pending',
              ),
            ),
          ],
        ));
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, VoidCallback onTap, bool isSelected) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected ? [color.withOpacity(0.8), color] : [
              AppTheme.surface.withOpacity(0.96),
              AppTheme.surface.withOpacity(0.84),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(isSelected ? 0.8 : 0.18), width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.3 : 0.12),
              blurRadius: isSelected ? 20 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.dashboardStatValue(isSelected ? Colors.white : color).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.dashboardStatLabel.copyWith(
                color: isSelected ? Colors.white.withOpacity(0.9) : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Set Schedule',
                Icons.schedule_outlined,
                AppTheme.info,
                controller.viewSchedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Patients',
                Icons.people,
                AppTheme.success,
                controller.viewPatients,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Manage Leaves',
                Icons.event_busy,
                AppTheme.primary,
                () => Get.toNamed('/doctor/leaves'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: const SizedBox(), // Empty spacer for alignment
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'All Appointments',
                Icons.list_alt,
                AppTheme.warning,
                controller.viewAllAppointments,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Booking Settings',
                Icons.settings_outlined,
                AppTheme.secondary,
                controller.viewBookingSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surface.withOpacity(0.96),
              AppTheme.surface.withOpacity(0.84),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.dashboardActionLabel(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAppointments() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Appointments",
                style: AppTheme.dashboardSectionTitle,
              ),
              if (controller.todayAppointments.isNotEmpty)
                TextButton(
                  onPressed: controller.viewAllAppointments,
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.todayAppointments.isEmpty)
            _buildEmptyState('No appointments scheduled for today')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.todayAppointments.length > 3
                  ? 3
                  : controller.todayAppointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final appointment = controller.todayAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            ),
        ],
      );
    });
  }

  Widget _buildUpcomingAppointments() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Upcoming Appointments',
                  style: AppTheme.dashboardSectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.upcomingAppointments.isEmpty)
            _buildEmptyState('No upcoming appointments yet')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.upcomingAppointments.length > 2
                  ? 2
                  : controller.upcomingAppointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final appointment = controller.upcomingAppointments[index];
                return _buildAppointmentCard(appointment);
              },
            ),
        ],
      );
    });
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return InkWell(
      onTap: () => controller.viewAppointment(appointment),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
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
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller
                        .getStatusColor(appointment.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.getStatusText(appointment.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: controller.getStatusColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(appointment.appointmentDate),
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 20),
                Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  timeFormat.format(appointment.appointmentDate),
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actions for doctor: confirm or decline pending/scheduled appointments
            if (appointment.isPending ||
                appointment.status.toLowerCase() == 'scheduled')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      Get.defaultDialog(
                        title: 'Confirm Appointment',
                        middleText: 'Mark this appointment as confirmed?',
                        textConfirm: 'Yes',
                        textCancel: 'No',
                        confirmTextColor: AppTheme.surface,
                        onConfirm: () {
                          Get.back();
                          controller.confirmAppointment(appointment.id);
                        },
                      );
                    },
                    icon: const Icon(Icons.check_circle, color: AppTheme.success),
                    label: const Text('Confirm'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final reasonController = TextEditingController();
                      Get.defaultDialog(
                        title: 'Decline Appointment',
                        content: Column(
                          children: [
                            const Text('Please provide a reason for declining:'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: reasonController,
                              decoration: const InputDecoration(
                                hintText: 'Reason...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        textConfirm: 'Decline',
                        textCancel: 'Close',
                        confirmTextColor: AppTheme.surface,
                        onConfirm: () {
                          if (reasonController.text.trim().isEmpty) {
                            Get.snackbar('Error', 'Reason is required',
                                backgroundColor: AppTheme.error.withOpacity(0.1),
                                colorText: AppTheme.error);
                            return;
                          }
                          Get.back();
                          controller.declineAppointment(appointment.id, reasonController.text.trim());
                        },
                      );
                    },
                    icon: const Icon(Icons.cancel, color: AppTheme.error),
                    label: const Text('Decline'),
                  ),
                ],
              )
            // Actions for doctor: Mark Confirmed appointment as Checked (Completed)
            else if (appointment.status.toLowerCase() == 'confirmed')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      Get.defaultDialog(
                        title: 'Mark as Checked',
                        middleText: 'Mark this appointment as Checked (Completed)?',
                        textConfirm: 'Yes',
                        textCancel: 'No',
                        confirmTextColor: AppTheme.surface,
                        onConfirm: () {
                          Get.back();
                          controller.markAsChecked(appointment.id);
                        },
                      );
                    },
                    icon: const Icon(Icons.done_all, color: AppTheme.success),
                    label: const Text('Mark as Checked'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final reasonController = TextEditingController();
                      Get.defaultDialog(
                        title: 'Cancel Appointment',
                        content: Column(
                          children: [
                            const Text('Please provide a reason for cancelling:'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: reasonController,
                              decoration: const InputDecoration(
                                hintText: 'Reason...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        textConfirm: 'Cancel Appointment',
                        textCancel: 'Close',
                        confirmTextColor: AppTheme.surface,
                        onConfirm: () {
                          if (reasonController.text.trim().isEmpty) {
                            Get.snackbar('Error', 'Reason is required',
                                backgroundColor: AppTheme.error.withOpacity(0.1),
                                colorText: AppTheme.error);
                            return;
                          }
                          Get.back();
                          controller.declineAppointment(appointment.id, reasonController.text.trim());
                        },
                      );
                    },
                    icon: const Icon(Icons.cancel, color: AppTheme.error),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.medical_services_outlined,
              size: 64, color: AppTheme.textSecondary.withOpacity(0.18)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
