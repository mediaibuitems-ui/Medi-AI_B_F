import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as download_helper;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  String selectedPeriod = 'This Month';

  bool isLoading = true;

  Map<String, dynamic> reportData = {
    'totalAppointments': 0,
    'completedAppointments': 0,
    'cancelledAppointments': 0,
    'pendingAppointments': 0,
    'totalUsers': 0,
    'newUsers': 0,
    'activeUsers': 0,
  };

  List<Map<String, dynamic>> monthlyTrends = [];
  List<Map<String, dynamic>> monthlyUserTrends = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final response = await _apiService.get('/Admin/dashboard-stats');
      if (response.success && response.data != null) {
        final data = response.data;
        setState(() {
          reportData = {
            'totalAppointments': data['totalAppointments'] ?? 0,
            'completedAppointments': data['completedAppointments'] ?? 0,
            'cancelledAppointments': data['cancelledAppointments'] ?? 0,
            'pendingAppointments': data['pendingAppointments'] ?? 0,
            'totalUsers': data['totalUsers'] ?? 0,
            'newUsers': data['newUsers'] ?? 0,
            'activeUsers': data['activeUsers'] ?? 0,
          };

          if (data['monthlyTrends'] != null && data['monthlyTrends'] is List) {
            monthlyTrends =
                List<Map<String, dynamic>>.from(data['monthlyTrends']);
          }
          if (data['monthlyUserTrends'] != null &&
              data['monthlyUserTrends'] is List) {
            monthlyUserTrends =
                List<Map<String, dynamic>>.from(data['monthlyUserTrends']);
          }

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }


  void _generateReport(String reportType) {
    Get.dialog(
      AlertDialog(
        title: const Text('Generate report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Which report would you like to generate?'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Today', 'This Week', 'This Month', 'This Year', 'Custom']
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(_periodLabel(period)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPeriod = value!;
                    });
                  },
                );
              }
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _downloadReport({
                  'name': '$reportType Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  'type': reportType,
                  'date': DateTime.now(),
                  'period': selectedPeriod,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Generate'),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadReport(Map<String, dynamic> report) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Generate CSV content
      String csvContent = await _generateReportCSV(report);

      Get.back(); // Close loading dialog

      if (kIsWeb) {
        // Web download
        await download_helper.downloadFile(csvContent, '${report['name']}.csv');
      } else {
        // Mobile download
        await download_helper.downloadFile(csvContent, '${report['name']}.csv');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Error',
        'Failed to generate report',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: AppTheme.surface,
      );
    }
  }

  Future<String> _generateReportCSV(Map<String, dynamic> report) async {
    final String reportName = report['name'];
    final String reportType = report['type'];
    final DateTime reportDate = report['date'];

    // Generate CSV header
    String csv = 'Report Name,Type,Generated Date\n';
    csv +=
        '$reportName,$reportType,${DateFormat('yyyy-MM-dd').format(reportDate)}\n\n';

    if (reportType == 'Appointments') {
      csv += 'Date,Patient,Doctor,Status,Time\n';

      // Fetch appointments
      final response = await _apiService.get('/Appointments');
      if (response.success && response.data != null) {
        final List<dynamic> appointments = response.data;
        for (var appt in appointments) {
          final dateTimeStr = appt['dateTime']?.toString() ?? '';
          final dateTime = DateTime.tryParse(dateTimeStr);
          final date =
              dateTime != null ? DateFormat('yyyy-MM-dd').format(dateTime) : '';
          final time =
              dateTime != null ? DateFormat('HH:mm').format(dateTime) : '';

          final patient = (appt['patientName'] ?? 'Unknown')
              .toString()
              .replaceAll('"', '""');
          final doctor = (appt['doctorName'] ?? 'Unknown')
              .toString()
              .replaceAll('"', '""');
          final status =
              (appt['status'] ?? 'Unknown').toString().replaceAll('"', '""');

          csv += '"$date","$patient","$doctor","$status","$time"\n';
        }
      }
    } else if (reportType == 'Users') {
      csv += 'Name,Email,Role,Status,Registration Date\n';

      // Fetch users
      final response = await _apiService.get('/Admin/users');
      if (response.success && response.data != null) {
        final List<dynamic> users = response.data;
        for (var user in users) {
          final name =
              (user['fullName'] ?? '').toString().replaceAll('"', '""');
          final email = (user['email'] ?? '').toString().replaceAll('"', '""');
          final role = (user['role'] ?? '').toString().replaceAll('"', '""');
          final status = (user['isActive'] == true) ? 'Active' : 'Inactive';
          final date = user['joinedDate'] != null
              ? DateFormat('yyyy-MM-dd')
                  .format(DateTime.parse(user['joinedDate'].toString()))
              : '';

          csv += '"$name","$email","$role","$status","$date"\n';
        }
      }
    } else if (reportType == 'Doctors') {
      csv += 'Name,Specialization,Rating,Status\n';

      // Fetch doctors
      final response = await _apiService.get('/Doctors');
      if (response.success && response.data != null) {
        final List<dynamic> doctors = response.data;
        for (var doc in doctors) {
          final name = (doc['user']?['fullName'] ?? doc['doctorName'] ?? '')
              .toString()
              .replaceAll('"', '""');
          final spec =
              (doc['specialization'] ?? '').toString().replaceAll('"', '""');
          final rating = doc['averageRating']?.toString() ?? '0.0';
          final status =
              (doc['isAvailable'] == true) ? 'Available' : 'Unavailable';

          csv += '"$name","$spec","$rating","$status"\n';
        }
      }
    }

    return csv;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ))
            else ...[
              // Statistics Overview
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total appointments',
                    reportData['totalAppointments'].toString(),
                    Icons.calendar_today,
                    AppTheme.primary,
                  ),
                  _buildStatCard(
                    'Completed',
                    reportData['completedAppointments'].toString(),
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                  _buildStatCard(
                    'Active users',
                    reportData['activeUsers'].toString(),
                    Icons.people,
                    AppTheme.warning,
                  ),
                  _buildStatCard(
                    'New users',
                    reportData['newUsers'].toString(),
                    Icons.person_add,
                    AppTheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Monthly Trends (Mock)
              Text(
                'Monthly Trends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
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
                    const Text('Appointments per Month',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: monthlyTrends.isEmpty
                            ? [const Text('No data available')]
                            : monthlyTrends.map((trend) {
                                final label = trend['label']?.toString() ?? '';
                                final value = double.tryParse(
                                        trend['value']?.toString() ?? '0') ??
                                    0;
                                final maxValue = monthlyTrends
                                    .map((t) =>
                                        double.tryParse(
                                            t['value']?.toString() ?? '0') ??
                                        0)
                                    .reduce((a, b) => a > b ? a : b);
                                final scaleMax =
                                    maxValue > 0 ? maxValue : 100.0;
                                return _buildBar(
                                    label, value, scaleMax, AppTheme.primary);
                              }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Registered Users per Month',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: monthlyUserTrends.isEmpty
                            ? [const Text('No data available')]
                            : monthlyUserTrends.map((trend) {
                                final label = trend['label']?.toString() ?? '';
                                final value = double.tryParse(
                                        trend['value']?.toString() ?? '0') ??
                                    0;
                                final maxValue = monthlyUserTrends
                                    .map((t) =>
                                        double.tryParse(
                                            t['value']?.toString() ?? '0') ??
                                        0)
                                    .reduce((a, b) => a > b ? a : b);
                                final scaleMax =
                                    maxValue > 0 ? maxValue : 100.0;
                                return _buildBar(
                                    label, value, scaleMax, AppTheme.success);
                              }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Generate Reports
              Text(
                'Generate reports',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildReportCard(
                    'Appointments',
                    Icons.calendar_month,
                    AppTheme.primary,
                    () => _generateReport('Appointments'),
                  ),
                  _buildReportCard(
                    'Users',
                    Icons.people,
                    AppTheme.success,
                    () => _generateReport('Users'),
                  ),
                  _buildReportCard(
                    'Doctors',
                    Icons.medical_services,
                    AppTheme.warning,
                    () => _generateReport('Doctors'),
                  ),
                ],
              ),
              const SizedBox(height: 32),


            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'generate',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'Today':
        return 'period_today';
      case 'This Week':
        return 'period_this_week';
      case 'This Month':
        return 'period_this_month';
      case 'This Year':
        return 'period_this_year';
      case 'Custom':
        return 'period_custom';
      default:
        return period;
    }
  }

  String _reportTypeLabel(String type) {
    switch (type) {
      case 'Appointments':
        return 'appointments';
      case 'Users':
        return 'users';
      case 'Doctors':
        return 'doctors_label';
      default:
        return type;
    }
  }

  Widget _buildBar(String label, double value, double maxValue, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: (value / maxValue) * 140,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
