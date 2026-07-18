import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';
import '../../../widgets/dashboard_stat_card.dart';
import '../../../widgets/dashboard_quick_action.dart';

export 'admin_dashboard_binding.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
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
                if (controller.isLoading.value &&
                    controller.currentUser.value == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }),
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildStatisticsGrid(),
              const SizedBox(height: 24),
              _buildTrendsCharts(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentActivities(),
              const SizedBox(height: 24),
              _buildSystemOverview(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.surface),
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text('Admin Dashboard'),
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.surface,
      elevation: 0,
      actions: [
        Obx(() {
          final alerts = controller.systemAlerts.value;
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context),
              ),
              if (alerts > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      alerts.toString(),
                      style: const TextStyle(
                        color: AppTheme.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                user?.name ?? 'Admin',
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
                    : const Icon(Icons.shield,
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
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Manage Users'),
                  onTap: () {
                    Get.back();
                    controller.manageUsers();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: const Text('Manage Doctors'),
                  onTap: () {
                    Get.back();
                    controller.manageDoctors();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_busy_outlined),
                  title: const Text('Doctor Leaves'),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/admin/doctor-leaves');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Verifications'),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/admin/verifications');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Appointments'),
                  onTap: () {
                    Get.back();
                    controller.viewAllAppointments();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Reports'),
                  onTap: () {
                    Get.back();
                    controller.viewReports();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Manage Feedback'),
                  onTap: () {
                    Get.back();
                    controller.manageFeedback();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('My Profile'),
                  onTap: () {
                    Get.back();
                    controller.viewProfile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('System Settings'),
                  onTap: () {
                    Get.back();
                    controller.systemSettings();
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
      return InkWell(
        onTap: controller.viewProfile,
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
                  Icons.admin_panel_settings,
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
                      backgroundImage: (user?.profileImage != null &&
                              user!.profileImage!.trim().isNotEmpty)
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: (user?.profileImage != null &&
                              user!.profileImage!.trim().isNotEmpty)
                          ? null
                          : const Icon(Icons.admin_panel_settings,
                              size: 32, color: AppTheme.surface),
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
                            user?.name ?? 'Administrator',
                            style: AppTheme.dashboardWelcomeName,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'System Administrator',
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

  Widget _buildStatisticsGrid() {
    return Obx(() => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    title: 'Total Users',
                    value: controller.totalUsers.value.toString(),
                    icon: Icons.people,
                    color: AppTheme.info,
                    onTap: controller.manageUsers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatCard(
                    title: 'Students',
                    value: controller.totalStudents.value.toString(),
                    icon: Icons.school,
                    color: AppTheme.success,
                    onTap: () => controller.manageUsers('Student'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatCard(
                    title: 'Faculty',
                    value: controller.totalFaculty.value.toString(),
                    icon: Icons.work,
                    color: AppTheme.warning,
                    onTap: () => controller.manageUsers('Faculty'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    title: 'Doctors',
                    value: controller.totalDoctors.value.toString(),
                    icon: Icons.medical_services,
                    color: AppTheme.secondary,
                    onTap: controller.manageDoctors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatCard(
                    title: 'Appointments',
                    value: controller.totalAppointments.value.toString(),
                    icon: Icons.calendar_today,
                    color: AppTheme.tertiary,
                    onTap: controller.viewAllAppointments,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatCard(
                    title: 'Pending',
                    value: controller.pendingVerifications.value.toString(),
                    icon: Icons.pending_actions,
                    color: AppTheme.error,
                    onTap: () => Get.toNamed('/admin/verifications'),
                  ),
                ),
              ],
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
                    label: 'Manage Users',
                    icon: Icons.people,
                    color: AppTheme.info,
                    onTap: controller.manageUsers,
                    index: 0,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'Manage Doctors',
                    icon: Icons.medical_services,
                    color: AppTheme.success,
                    onTap: controller.manageDoctors,
                    index: 1,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'Reports',
                    icon: Icons.assessment,
                    color: AppTheme.warning,
                    onTap: controller.viewReports,
                    index: 2,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'Verifications',
                    icon: Icons.verified_user,
                    color: AppTheme.error,
                    onTap: () => Get.toNamed('/admin/verifications'),
                    index: 3,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'Doctor Leaves',
                    icon: Icons.event_busy,
                    color: AppTheme.primary,
                    onTap: () => Get.toNamed('/admin/doctor-leaves'),
                    index: 4,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardQuickAction(
                    label: 'System Settings',
                    icon: Icons.settings,
                    color: AppTheme.secondary,
                    onTap: controller.systemSettings,
                    index: 5,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: AppTheme.dashboardSectionTitle,
          ),
          const SizedBox(height: 12),
          if (controller.recentActivities.isEmpty)
            _buildEmptyState('No recent activity to show yet')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentActivities.length > 4
                  ? 4
                  : controller.recentActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = controller.recentActivities[index];
                final title =
                    (activity['title'] ?? activity['Title'] ?? 'Activity')
                        .toString();
                final description = (activity['description'] ??
                        activity['Description'] ??
                        activity['message'] ??
                        activity['Message'] ??
                        '')
                    .toString();
                final createdAt =
                    (activity['createdAt'] ?? activity['CreatedAt'] ?? '')
                        .toString();

                return Container(
                  padding: const EdgeInsets.all(16),
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
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textPrimary.withOpacity(0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (createdAt.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                createdAt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      );
    });
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
            Icon(Icons.notifications_off_outlined,
                size: 64, color: AppTheme.textSecondary.withOpacity(0.18)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: AppTheme.dashboardSectionTitle,
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              Obx(() => _buildOverviewRow(
                    'Today Appointments',
                    controller.todayAppointments.value.toString(),
                    Icons.event_available,
                    AppTheme.success,
                  )),
              const Divider(height: 24),
              Obx(() => _buildOverviewRow(
                    'Pending Verifications',
                    controller.pendingVerifications.value.toString(),
                    Icons.pending_actions,
                    AppTheme.warning,
                  )),
              const Divider(height: 24),
              Obx(() => _buildOverviewRow(
                    'System Alerts',
                    controller.systemAlerts.value.toString(),
                    Icons.warning_amber,
                    AppTheme.error,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(
      String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (controller.notifications.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 48,
                      color: AppTheme.textSecondary.withOpacity(0.18)),
                  const SizedBox(height: 16),
                  const Text('No notifications'),
                ],
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: controller.notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                return ListTile(
                  leading:
                      const Icon(Icons.info_outline, color: AppTheme.primary),
                  title: Text(notification['title'] ?? 'Notification'),
                  subtitle: Text(notification['message'] ?? ''),
                  trailing: Text(
                    (notification['time'] ??
                            notification['Time'] ??
                            notification['createdAt'] ??
                            '')
                        .toString(),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCharts() {
    return Obx(() {
      if (controller.monthlyTrends.isEmpty &&
          controller.monthlyUserTrends.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Trends',
            style: AppTheme.dashboardSectionTitle,
          ),
          const SizedBox(height: 12),
          Container(
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
                if (controller.monthlyTrends.isNotEmpty) ...[
                  const Text('Appointments (Last 6 Months)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: _buildLineChart(
                        controller.monthlyTrends, AppTheme.primary),
                  ),
                ],
                if (controller.monthlyUserTrends.isNotEmpty) ...[
                  if (controller.monthlyTrends.isNotEmpty)
                    const SizedBox(height: 40),
                  const Text('Registered Users (Last 6 Months)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: _buildLineChart(
                        controller.monthlyUserTrends, AppTheme.success),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLineChart(List<Map<String, dynamic>> dataList, Color lineColor) {
    if (dataList.isEmpty) return const SizedBox();

    final List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 0; i < dataList.length; i++) {
      final val = double.tryParse(dataList[i]['value']?.toString() ?? '0') ?? 0;
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (maxY == 0) maxY = 10;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textSecondary.withOpacity(0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dataList.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dataList[index]['label']?.toString() ?? '',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY / 4) > 0 ? (maxY / 4) : 1,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dataList.length - 1).toDouble(),
        minY: 0,
        maxY: maxY + (maxY * 0.2), // 20% padding top
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
