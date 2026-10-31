class Region {
  Region({required this.name, required this.state, required this.city});

  final String name;
  final String state;
  final String city;

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
    );
  }
}

class ContentBlock {
  ContentBlock({
    required this.title,
    required this.body,
    required this.placement,
    this.sortOrder = 0,
  });

  final String title;
  final String body;
  final String placement;
  final int sortOrder;

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      placement: json['placement']?.toString() ?? '',
      sortOrder: int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
    );
  }
}

class Therapy {
  Therapy({required this.name, required this.summary});

  final String name;
  final String summary;

  factory Therapy.fromJson(Map<String, dynamic> json) {
    return Therapy(
      name: json['therapy_name']?.toString() ?? json['name']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class Testimonial {
  Testimonial({required this.quote, required this.displayName, required this.rating});

  final String quote;
  final String displayName;
  final int rating;

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      quote: json['quote']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      rating: int.tryParse('${json['rating'] ?? 0}') ?? 0,
    );
  }
}

class HomeContent {
  HomeContent({
    required this.regions,
    required this.blocks,
    required this.therapies,
    required this.testimonials,
  });

  final List<Region> regions;
  final List<ContentBlock> blocks;
  final List<Therapy> therapies;
  final List<Testimonial> testimonials;

  ContentBlock? block(String placement) {
    for (final item in blocks) {
      if (item.placement == placement) return item;
    }
    return null;
  }

  List<ContentBlock> steps() {
    final rows = blocks.where((item) => item.placement == 'home_steps').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows;
  }

  factory HomeContent.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(dynamic value, T Function(Map<String, dynamic>) build) {
      final rows = value is List ? value : const [];
      return rows.whereType<Map>().map((row) => build(Map<String, dynamic>.from(row))).toList();
    }

    return HomeContent(
      regions: mapList(json['regions'], Region.fromJson),
      blocks: mapList(json['blocks'], ContentBlock.fromJson),
      therapies: mapList(json['therapies'], Therapy.fromJson),
      testimonials: mapList(json['testimonials'], Testimonial.fromJson),
    );
  }

  static HomeContent fallback() {
    return HomeContent(
      regions: [
        Region(name: 'Kochi', state: 'Kerala', city: 'Kochi'),
        Region(name: 'Bengaluru', state: 'Karnataka', city: 'Bengaluru'),
      ],
      blocks: [
        ContentBlock(
          title: 'Healing rooted in ancient wisdom, close to home.',
          body:
              'Find trusted Ayurveda doctors and Panchakarma therapists in your region. Compare profiles, check availability, and book your consultation in minutes.',
          placement: 'home_hero',
        ),
        ContentBlock(
          title: 'Choose your region',
          body: "Tell us where you are and we'll show practitioners who serve your area.",
          placement: 'home_steps',
          sortOrder: 1,
        ),
        ContentBlock(
          title: 'Explore verified profiles',
          body: 'Compare qualifications, specialties, experience and consultation fees.',
          placement: 'home_steps',
          sortOrder: 2,
        ),
        ContentBlock(
          title: 'Book your appointment',
          body: 'Pick a time that suits you and get confirmation from your practitioner.',
          placement: 'home_steps',
          sortOrder: 3,
        ),
      ],
      therapies: [
        Therapy(name: 'Panchakarma', summary: 'Deep detox and rejuvenation'),
        Therapy(name: 'Abhyanga', summary: 'Warm herbal oil massage'),
        Therapy(name: 'Shirodhara', summary: 'Calming oil flow therapy'),
        Therapy(name: 'Herbal medicine', summary: 'Personalised formulations'),
        Therapy(name: 'Diet & lifestyle', summary: 'Dosha-based guidance'),
        Therapy(name: 'Chronic care', summary: 'Joint, skin and digestion'),
      ],
      testimonials: [
        Testimonial(
          quote: 'The clinic visit felt careful and unhurried.',
          displayName: 'Meera Nair',
          rating: 5,
        ),
      ],
    );
  }
}

class PractitionerCard {
  PractitionerCard({
    required this.name,
    required this.practitionerName,
    required this.practitionerType,
    required this.qualifications,
    required this.bio,
    required this.clinicAddress,
    required this.fees,
    required this.therapies,
    required this.regions,
    required this.ratingAverage,
    required this.ratingCount,
    this.status,
    this.registrationNumber,
    this.phone = '',
    this.yearsExperience = 0,
    this.languages = '',
    this.testimonials = const [],
  });

  final String name;
  final String practitionerName;
  final String practitionerType;
  final String qualifications;
  final String bio;
  final String clinicAddress;
  final Map<String, double> fees;
  final List<String> therapies;
  final List<String> regions;
  final double ratingAverage;
  final int ratingCount;
  final String? status;
  final String? registrationNumber;
  final String phone;
  final int yearsExperience;
  final String languages;
  final List<Testimonial> testimonials;

  factory PractitionerCard.fromJson(Map<String, dynamic> json) {
    final rawFees = json['fees'] is Map ? Map<String, dynamic>.from(json['fees'] as Map) : {};
    double fee(String key) => double.tryParse('${rawFees[key] ?? 0}') ?? 0;
    final therapies = (json['therapies'] as List?)?.map((item) => item.toString()).toList() ?? [];
    final regions = (json['regions'] as List?)?.map((item) => item.toString()).toList() ?? [];
    final quotes = json['testimonials'] is List
        ? (json['testimonials'] as List)
            .whereType<Map>()
            .map((row) => Testimonial.fromJson(Map<String, dynamic>.from(row)))
            .toList()
        : <Testimonial>[];
    return PractitionerCard(
      name: json['name']?.toString() ?? '',
      practitionerName: json['practitioner_name']?.toString() ?? '',
      practitionerType: json['practitioner_type']?.toString() ?? '',
      qualifications: json['qualifications']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      clinicAddress: json['clinic_address']?.toString() ?? '',
      fees: {'clinic': fee('clinic'), 'video': fee('video'), 'home': fee('home')},
      therapies: therapies,
      regions: regions,
      ratingAverage: double.tryParse('${json['rating_average'] ?? 0}') ?? 0,
      ratingCount: int.tryParse('${json['rating_count'] ?? 0}') ?? 0,
      status: json['status']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      phone: json['phone']?.toString() ?? '',
      yearsExperience: int.tryParse('${json['years_experience'] ?? 0}') ?? 0,
      languages: json['languages']?.toString() ?? '',
      testimonials: quotes,
    );
  }
}

class Slot {
  Slot({required this.start, required this.end});
  final String start;
  final String end;

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(start: json['start'].toString(), end: json['end'].toString());
  }
}

class AppointmentItem {
  AppointmentItem({
    required this.name,
    required this.patientName,
    required this.practitionerName,
    required this.practitioner,
    required this.therapy,
    required this.visitType,
    required this.startsOn,
    required this.fee,
    required this.status,
    this.meetingUrl,
  });

  final String name;
  final String patientName;
  final String practitionerName;
  final String practitioner;
  final String therapy;
  final String visitType;
  final String startsOn;
  final double fee;
  final String status;
  final String? meetingUrl;

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    return AppointmentItem(
      name: json['name']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? '',
      practitionerName: json['practitioner_name']?.toString() ?? '',
      practitioner: json['practitioner']?.toString() ?? '',
      therapy: json['therapy']?.toString() ?? '',
      visitType: json['visit_type']?.toString() ?? '',
      startsOn: json['starts_on']?.toString() ?? '',
      fee: double.tryParse('${json['fee'] ?? 0}') ?? 0,
      status: json['status']?.toString() ?? '',
      meetingUrl: json['meeting_url']?.toString(),
    );
  }
}

class PaymentOrder {
  PaymentOrder({
    required this.appointment,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.devMode,
  });

  final String appointment;
  final String orderId;
  final int amount;
  final String currency;
  final String keyId;
  final bool devMode;

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      appointment: json['appointment']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      amount: int.tryParse('${json['amount'] ?? 0}') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      keyId: json['key_id']?.toString() ?? '',
      devMode: json['dev_mode'] == true,
    );
  }
}

class ClinicalRecord {
  ClinicalRecord({this.note, this.prescription});

  final Map<String, dynamic>? note;
  final Map<String, dynamic>? prescription;

  factory ClinicalRecord.fromJson(Map<String, dynamic> json) {
    return ClinicalRecord(
      note: json['note'] is Map ? Map<String, dynamic>.from(json['note'] as Map) : null,
      prescription: json['prescription'] is Map ? Map<String, dynamic>.from(json['prescription'] as Map) : null,
    );
  }
}

class AppNotification {
  AppNotification({required this.subject, required this.message, required this.created});

  final String subject;
  final String message;
  final String created;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      subject: json['subject']?.toString() ?? '',
      message: json['email_content']?.toString() ?? '',
      created: json['creation']?.toString() ?? '',
    );
  }
}

class Session {
  Session({
    required this.token,
    required this.user,
    required this.fullName,
    required this.phone,
    required this.roles,
    this.patient,
    this.practitioner,
  });

  final String token;
  final String user;
  final String fullName;
  final String phone;
  final List<String> roles;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? practitioner;

  bool get isPatient => roles.contains('Patient') || (patient != null && practitioner == null);
  bool get isPractitioner => roles.contains('Practitioner') || practitioner != null;

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user,
        'full_name': fullName,
        'phone': phone,
        'roles': roles,
        'patient': patient,
        'practitioner': practitioner,
      };

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['token']?.toString() ?? '',
      user: json['user']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roles: _roleList(json['roles']),
      patient: json['patient'] is Map ? Map<String, dynamic>.from(json['patient'] as Map) : null,
      practitioner: json['practitioner'] is Map ? Map<String, dynamic>.from(json['practitioner'] as Map) : null,
    );
  }

  static List<String> _roleList(dynamic value) {
    if (value is List) return value.map((role) => role.toString()).toList();
    if (value is String && value.isNotEmpty) return [value];
    return const [];
  }
}
