class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final DateTime dateTime;
  final String status; // Pending, Confirmed, Completed, Cancelled
  final String? symptoms;
  final String? notes;
  final String? prescription;
  final DateTime createdAt;

  // Convenience getters
  String get reason => symptoms ?? 'General Consultation';
  DateTime get appointmentDate => dateTime;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
    this.symptoms,
    this.notes,
    this.prescription,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, ['id', 'Id']);
    final patientId = _readString(json, ['patientId', 'PatientId']);
    final patientName = _readString(json, ['patientName', 'PatientName']);
    final doctorId = _readString(json, ['doctorId', 'DoctorId']);
    final doctorName = _readString(json, ['doctorName', 'DoctorName']);
    final specialization =
        _readString(json, ['specialization', 'Specialization']);
    final status = _readString(json, ['status', 'Status'], fallback: 'Pending');
    final symptoms = _readNullableString(json, ['symptoms', 'Symptoms']);
    final notes = _readNullableString(json, ['notes', 'Notes']);
    final prescription =
        _readNullableString(json, ['prescription', 'Prescription']);
    final dateTimeText = _readString(json, ['dateTime', 'DateTime']);
    final createdAtText = _readString(
      json,
      ['createdAt', 'CreatedAt'],
      fallback: DateTime.now().toIso8601String(),
    );

    return Appointment(
      id: id,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      specialization: specialization,
      dateTime: DateTime.tryParse(dateTimeText) ?? DateTime.now(),
      status: status,
      symptoms: symptoms,
      notes: notes,
      prescription: prescription,
      createdAt: DateTime.tryParse(createdAtText) ?? DateTime.now(),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialization': specialization,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'symptoms': symptoms,
      'notes': notes,
      'prescription': prescription,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get canCancel => isPending || isConfirmed;
  bool get canReschedule => isPending;
}
