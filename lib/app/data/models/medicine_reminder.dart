import 'package:hive/hive.dart';

part 'medicine_reminder.g.dart';

@HiveType(typeId: 0)
class MedicineReminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicineName;

  @HiveField(2)
  String dosage;

  @HiveField(3)
  List<String> times; // ["09:00 AM", "02:00 PM", "09:00 PM"]

  @HiveField(4)
  List<String> days; // ["Monday", "Tuesday", "Wednesday"]

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime? endDate;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  bool isSynced;

  MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.times,
    required this.days,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.notes,
    this.isSynced = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'times': times,
      'days': days,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'isSynced': isSynced,
    };
  }

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      times: List<String>.from(json['times'] ?? []),
      days: List<String>.from(json['days'] ?? []),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      isSynced: json['isSynced'] ?? true,
    );
  }
}
