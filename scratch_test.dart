import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  // Don't set tz.local explicitly, let it default to UTC
  
  // Simulate device local time being PKT (UTC+5), let's say it's 2026-06-21 14:00:00 PKT
  // We can't fake DateTime.now(), so we'll just use the actual DateTime.now()
  var targetDateTime = DateTime.now().add(Duration(minutes: 5));
  print('Target DateTime: $targetDateTime, isUtc: ${targetDateTime.isUtc}');
  
  var now = tz.TZDateTime.now(tz.local);
  print('Now TZDateTime: $now');
  
  var scheduledDate = tz.TZDateTime.from(targetDateTime, tz.local);
  print('Scheduled TZDateTime: $scheduledDate');
  
  if (scheduledDate.isBefore(now)) {
    print('Scheduled date is before now! Adding 1 day.');
  } else {
    print('Scheduled date is in the future.');
  }
}
