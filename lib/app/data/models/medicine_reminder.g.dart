// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine_reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineReminderAdapter extends TypeAdapter<MedicineReminder> {
  @override
  final int typeId = 0;

  @override
  MedicineReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicineReminder(
      id: fields[0] as String,
      medicineName: fields[1] as String,
      dosage: fields[2] as String,
      times: (fields[3] as List).cast<String>(),
      days: (fields[4] as List).cast<String>(),
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime?,
      isActive: fields[7] as bool,
      notes: fields[8] as String?,
      isSynced: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MedicineReminder obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineName)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.times)
      ..writeByte(4)
      ..write(obj.days)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
