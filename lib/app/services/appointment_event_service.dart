import 'dart:async';

import 'package:get/get.dart';

class AppointmentEvent {
  final String appointmentId;
  final String action; // 'created', 'updated', 'cancelled'

  AppointmentEvent(this.appointmentId, this.action);
}

class AppointmentEventService extends GetxService {
  final StreamController<AppointmentEvent> _controller =
      StreamController<AppointmentEvent>.broadcast();

  Stream<AppointmentEvent> get stream => _controller.stream;

  void emit(AppointmentEvent event) {
    try {
      _controller.add(event);
    } catch (_) {}
  }

  @override
  void onClose() {
    _controller.close();
    super.onClose();
  }
}
