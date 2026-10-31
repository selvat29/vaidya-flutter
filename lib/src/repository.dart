import 'api_client.dart';
import 'models.dart';

class VaidyaRepository {
  VaidyaRepository(this.client);

  final ApiClient client;

  Future<HomeContent> home(String? region) async {
    final data = await client.call('vaidya.api.content.get_home', {
      if (region != null && region.isNotEmpty) 'region': region,
    });
    return HomeContent.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<PractitionerCard>> search({
    required String region,
    String? therapy,
    String? visitType,
  }) async {
    final data = await client.call('vaidya.api.practitioner.search', {
      'region': region,
      if (therapy != null && therapy.isNotEmpty) 'therapy': therapy,
      if (visitType != null && visitType.isNotEmpty) 'visit_type': visitType,
    });
    return (data as List)
        .whereType<Map>()
        .map((row) => PractitionerCard.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<PractitionerCard> profile(String name) async {
    final data = await client.call('vaidya.api.practitioner.get_profile', {'name': name});
    return PractitionerCard.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Slot>> slots(String practitioner, String date, String visitType) async {
    final data = await client.call('vaidya.api.practitioner.get_slots', {
      'practitioner': practitioner,
      'date': date,
      'visit_type': visitType,
    });
    return (data as List).whereType<Map>().map((row) => Slot.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<Map<String, dynamic>> sendOtp(String phone, String role) async {
    final data = await client.call('vaidya.api.auth.send_otp', {'phone': phone, 'role': role});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Session> verifyOtp({
    required String phone,
    required String otp,
    required String role,
    String? fullName,
  }) async {
    final data = await client.call('vaidya.api.auth.verify_otp', {
      'phone': phone,
      'otp': otp,
      'role': role,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    });
    return Session.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Session> me(String token) async {
    final data = await ApiClient(baseUrl: client.baseUrl, token: token).call('vaidya.api.auth.me');
    return Session.fromJson({...Map<String, dynamic>.from(data as Map), 'token': token});
  }

  Future<AppointmentItem> book({
    required String practitioner,
    required String therapy,
    required String visitType,
    required String startsOn,
  }) async {
    final data = await client.call('vaidya.api.booking.create', {
      'practitioner': practitioner,
      'therapy': therapy,
      'visit_type': visitType,
      'starts_on': startsOn,
      'consent': 1,
    });
    return AppointmentItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PaymentOrder> createOrder(String appointment) async {
    final data = await client.call('vaidya.api.payment.create_order', {'appointment': appointment});
    return PaymentOrder.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> markPaidDev(String appointment) async {
    await client.call('vaidya.api.payment.mark_paid_dev', {'appointment': appointment});
  }

  Future<List<AppointmentItem>> myAppointments() async {
    final data = await client.call('vaidya.api.booking.my_appointments');
    return (data as List)
        .whereType<Map>()
        .map((row) => AppointmentItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> cancel(String appointment) async {
    await client.call('vaidya.api.booking.cancel', {'appointment': appointment});
  }

  Future<void> complete(String appointment) async {
    await client.call('vaidya.api.booking.complete', {'appointment': appointment});
  }

  Future<void> setMeetingUrl(String appointment, String url) async {
    await client.call('vaidya.api.booking.set_meeting_url', {
      'appointment': appointment,
      'meeting_url': url,
    });
  }

  Future<ClinicalRecord> clinicalFor(String appointment) async {
    final data = await client.call('vaidya.api.clinical.get_for_appointment', {'appointment': appointment});
    return ClinicalRecord.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveNote({
    required String appointment,
    required String chiefComplaint,
    required String observations,
    required String advice,
    required bool shareWithPatient,
    required bool submit,
  }) async {
    await client.call('vaidya.api.clinical.save_note', {
      'appointment': appointment,
      'chief_complaint': chiefComplaint,
      'observations': observations,
      'advice': advice,
      'share_with_patient': shareWithPatient ? 1 : 0,
      'submit': submit ? 1 : 0,
    });
  }

  Future<void> submitPrescription({
    required String appointment,
    required List<Map<String, String>> items,
    String? advice,
  }) async {
    await client.call('vaidya.api.clinical.submit_prescription', {
      'appointment': appointment,
      'items': items,
      if (advice != null) 'advice': advice,
    });
  }

  Future<PractitionerCard> savePractitioner(Map<String, dynamic> values) async {
    final data = await client.call('vaidya.api.practitioner.save_profile', values);
    return PractitionerCard.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PractitionerCard> submitForReview() async {
    final data = await client.call('vaidya.api.practitioner.submit_for_review');
    return PractitionerCard.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Map<String, dynamic>>> availability() async {
    final data = await client.call('vaidya.api.practitioner.get_availability');
    return (data as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> setAvailability(List<Map<String, dynamic>> rows) async {
    await client.call('vaidya.api.practitioner.set_availability', {'rows': rows});
  }

  Future<void> savePatient(Map<String, dynamic> values) async {
    await client.call('vaidya.api.practitioner.save_patient_profile', values);
  }

  Future<List<AppNotification>> notifications() async {
    final data = await client.call('vaidya.api.notifications.mine');
    return (data as List)
        .whereType<Map>()
        .map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
