import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'models.dart';
import 'session.dart';
import 'theme.dart';
import 'widgets.dart';

const _languages = [
  'English',
  'Hindi',
  'Malayalam',
  'Tamil',
  'Kannada',
  'Telugu',
  'Marathi',
  'Bengali',
  'Gujarati',
  'Punjabi',
];

class PracticeProfilePage extends ConsumerStatefulWidget {
  const PracticeProfilePage({super.key});

  @override
  ConsumerState<PracticeProfilePage> createState() => _PracticeProfilePageState();
}

class _PracticeProfilePageState extends ConsumerState<PracticeProfilePage> {
  final name = TextEditingController();
  final qualifications = TextEditingController();
  final registration = TextEditingController();
  final bio = TextEditingController();
  final address = TextEditingController();
  final feeClinic = TextEditingController();
  final feeVideo = TextEditingController();
  final feeHome = TextEditingController();
  final years = TextEditingController(text: '0');
  String type = 'Doctor';
  final Set<String> therapies = {};
  final Set<String> regions = {};
  final Set<String> spoken = {'English'};
  bool seeded = false;

  @override
  void dispose() {
    for (final controller in [name, qualifications, registration, bio, address, feeClinic, feeVideo, feeHome, years]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _seed(PractitionerCard card) {
    if (seeded) return;
    seeded = true;
    name.text = card.practitionerName;
    qualifications.text = card.qualifications;
    registration.text = card.registrationNumber ?? '';
    bio.text = card.bio;
    address.text = card.clinicAddress;
    feeClinic.text = (card.fees['clinic'] ?? 0).toStringAsFixed(0);
    feeVideo.text = (card.fees['video'] ?? 0).toStringAsFixed(0);
    feeHome.text = (card.fees['home'] ?? 0).toStringAsFixed(0);
    type = card.practitionerType.isEmpty ? 'Doctor' : card.practitionerType;
    years.text = '${card.yearsExperience}';
    spoken
      ..clear()
      ..addAll(card.languages.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty));
    if (spoken.isEmpty) spoken.add('English');
    therapies.addAll(card.therapies);
    regions.addAll(card.regions);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).asData?.value;
    final id = session?.practitioner?['name']?.toString();
    if (id == null) {
      return const Center(child: Text('Complete sign-in as a practitioner.'));
    }
    return FutureBuilder<PractitionerCard>(
      future: ref.read(repositoryProvider).profile(id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        _seed(snapshot.data!);
        return _ProfileForm(
          name: name,
          qualifications: qualifications,
          registration: registration,
          bio: bio,
          years: years,
          type: type,
          spoken: spoken,
          onType: (value) => setState(() => type = value),
          onLanguage: (language, selected) => setState(() {
            if (selected) {
              spoken.add(language);
            } else {
              spoken.remove(language);
            }
          }),
          onSubmit: () => _save(submit: true),
        );
      },
    );
  }

  Future<void> _save({required bool submit}) async {
    try {
      final repo = ref.read(repositoryProvider);
      await repo.savePractitioner({
        'practitioner_name': name.text.trim(),
        'practitioner_type': type,
        'qualifications': qualifications.text.trim(),
        'registration_number': registration.text.trim(),
        'bio': bio.text.trim(),
        'clinic_address': address.text.trim(),
        'fee_clinic': num.tryParse(feeClinic.text) ?? 0,
        'fee_video': num.tryParse(feeVideo.text) ?? 0,
        'fee_home': num.tryParse(feeHome.text) ?? 0,
        'years_experience': int.tryParse(years.text) ?? 0,
        'languages': spoken.join(', '),
        'therapies': therapies.toList(),
        'regions': regions.toList(),
      });
      if (submit) await repo.submitForReview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(submit ? 'Submitted for review' : 'Profile saved')));
      }
    } on ApiException catch (error) {
      if (mounted) await showError(context, error);
    }
  }
}

class PractitionerIntroPage extends StatelessWidget {
  const PractitionerIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 28, wide ? 48 : 20, 12),
          child: PageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRACTITIONER PORTAL', style: bodyStyle(size: 12, color: sage, weight: FontWeight.w700).copyWith(letterSpacing: 1.4)),
                SizedBox(height: 10),
                _IntroTitle(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            children: [
              Text('Sign in to create your practitioner profile', textAlign: TextAlign.center, style: displayStyle(size: wide ? 32 : 26)),
              const SizedBox(height: 8),
              Text('It takes about five minutes. Your profile goes live after a quick verification.', textAlign: TextAlign.center, style: bodyStyle()),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _IntroCard(Icons.groups_outlined, 'Reach patients in your\nregion'),
                  _IntroCard(Icons.calendar_month_outlined, 'Share your weekly\navailability'),
                  _IntroCard(Icons.verified_outlined, 'Verified badge after\nreview'),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => context.go('/sign-in?role=Practitioner'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Sign in to get started'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const VaidyaFooter(),
      ],
    );
  }
}

class _IntroTitle extends StatelessWidget {
  const _IntroTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Vaidya profile', style: displayStyle(size: 48)),
        const SizedBox(height: 8),
        Text('Share your expertise with patients searching for authentic Ayurvedic care near them.', style: bodyStyle()),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          Icon(icon, color: ink),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: bodyStyle(size: 14, color: ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.name,
    required this.qualifications,
    required this.registration,
    required this.bio,
    required this.years,
    required this.type,
    required this.spoken,
    required this.onType,
    required this.onLanguage,
    required this.onSubmit,
  });

  final TextEditingController name;
  final TextEditingController qualifications;
  final TextEditingController registration;
  final TextEditingController bio;
  final TextEditingController years;
  final String type;
  final Set<String> spoken;
  final ValueChanged<String> onType;
  final void Function(String language, bool selected) onLanguage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I am joining as', style: bodyStyle(size: 14, color: ink, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _RoleCard(
              title: 'Ayurveda doctor',
              body: 'BAMS / MD (Ayu) consultations, diagnosis and prescriptions',
              selected: type == 'Doctor',
              onTap: () => onType('Doctor'),
              width: wide ? 280 : double.infinity,
            ),
            _RoleCard(
              title: 'Ayurveda therapist',
              body: 'Panchakarma, Abhyanga, Shirodhara and other therapies',
              selected: type == 'Therapist',
              onTap: () => onType('Therapist'),
              width: wide ? 280 : double.infinity,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E4DC),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.person, color: Color(0xFF8C918A), size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.photo_camera_outlined, size: 16),
                    label: const Text('Upload photo'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFE7EFE4),
                      foregroundColor: green,
                      side: const BorderSide(color: Color(0xFFD5E0D2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('A clear, professional photo builds patient trust. JPG or PNG, up to 5 MB.', style: bodyStyle(size: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _pair(
          wide,
          _labeled('Full name', TextField(controller: name)),
          _labeled('Qualification', TextField(controller: qualifications)),
        ),
        const SizedBox(height: 14),
        _pair(
          wide,
          _labeled('Registration number (optional)', TextField(controller: registration)),
          _labeled('Years of experience', TextField(controller: years, keyboardType: TextInputType.number)),
        ),
        const SizedBox(height: 14),
        _labeled(
          'Bio',
          TextField(
            controller: bio,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(hintText: 'Share your approach to healing, your training, and what patients can expect.'),
          ),
        ),
        const SizedBox(height: 8),
        Text('Languages spoken', style: bodyStyle(size: 14, color: ink, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final language in _languages)
              FilterChip(
                label: Text(spoken.contains(language) ? '✓ $language' : language),
                selected: spoken.contains(language),
                showCheckmark: false,
                selectedColor: green,
                labelStyle: bodyStyle(size: 14, color: spoken.contains(language) ? Colors.white : ink, weight: FontWeight.w600),
                backgroundColor: Colors.white,
                side: BorderSide(color: spoken.contains(language) ? green : line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (selected) => onLanguage(language, selected),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Submit for review'),
          ),
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 48 : 16, 12, wide ? 48 : 16, 48),
      children: [
        PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRACTITIONER PORTAL', style: bodyStyle(size: 12, color: sage, weight: FontWeight.w700).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 8),
              Text('Your Vaidya profile', style: displayStyle(size: wide ? 48 : 34)),
              const SizedBox(height: 8),
              Text('Share your expertise with patients searching for authentic Ayurvedic care near them.', style: bodyStyle()),
              const SizedBox(height: 18),
              const Divider(color: line),
              const SizedBox(height: 18),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step 1', style: bodyStyle(size: 13, color: muted)),
                          Text('About you', style: displayStyle(size: 28)),
                          const SizedBox(height: 8),
                          Text('Tell patients who you are and how you practise.', style: bodyStyle(size: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: form),
                  ],
                )
              else
                form,
            ],
          ),
        ),
      ],
    );
  }

  Widget _pair(bool wide, Widget left, Widget right) {
    if (!wide) {
      return Column(children: [left, const SizedBox(height: 14), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _labeled(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FieldLabel(label), field],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    required this.width,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? selectedFill : idleFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? green : Colors.transparent, width: 1.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: displayStyle(size: 20)),
            const SizedBox(height: 6),
            Text(body, style: bodyStyle(size: 14)),
          ],
        ),
      ),
    );
  }
}

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});

  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _DayHours {
  _DayHours({required this.enabled, this.start = '09:00', this.end = '17:00'});
  bool enabled;
  String start;
  String end;
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  final city = TextEditingController();
  final stateName = TextEditingController();
  final phone = TextEditingController();
  final fee = TextEditingController(text: '500');
  int slotMinutes = 30;
  bool clinic = true;
  bool video = false;
  bool home = false;
  bool loaded = false;
  final days = {
    for (final day in const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])
      day: _DayHours(enabled: day != 'Saturday' && day != 'Sunday'),
  };

  @override
  void dispose() {
    city.dispose();
    stateName.dispose();
    phone.dispose();
    fee.dispose();
    super.dispose();
  }

  void _applyRows(List<Map<String, dynamic>> rows) {
    if (loaded) return;
    loaded = true;
    final profile = ref.read(sessionProvider).asData?.value?.practitioner;
    if (phone.text.isEmpty) phone.text = profile?['phone']?.toString() ?? '';
    final regions = profile?['regions'];
    if (city.text.isEmpty && regions is List && regions.isNotEmpty) city.text = regions.first.toString();
    final fees = profile?['fees'];
    if (fees is Map && fee.text == '500') {
      final clinicFee = fees['clinic'];
      if (clinicFee != null) fee.text = clinicFee.toString().replaceAll('.0', '');
    }
    if (rows.isEmpty) return;
    for (final day in days.values) {
      day.enabled = false;
    }
    for (final row in rows) {
      final name = row['weekday']?.toString();
      final day = days[name];
      if (day == null) continue;
      day.enabled = true;
      day.start = (row['start_time']?.toString() ?? '09:00:00').substring(0, 5);
      day.end = (row['end_time']?.toString() ?? '17:00:00').substring(0, 5);
      slotMinutes = int.tryParse('${row['slot_minutes'] ?? 30}') ?? 30;
      clinic = '${row['allow_clinic']}' != '0';
      video = '${row['allow_video']}' != '0';
      home = '${row['allow_home']}' != '0';
    }
  }

  String _clock(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? parts[1] : '00';
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loaded ? null : ref.read(repositoryProvider).availability(),
      builder: (context, snapshot) {
        if (!loaded && snapshot.hasData) {
          _applyRows(snapshot.data!);
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 56 : 16, 12, wide ? 56 : 16, 28),
              child: PageFrame(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 260, child: _stepCopy()),
                          const SizedBox(width: 28),
                          Expanded(child: _hoursForm(wide)),
                        ],
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_stepCopy(), const SizedBox(height: 20), _hoursForm(wide)]),
              ),
            ),
            const VaidyaFooter(dark: true),
          ],
        );
      },
    );
  }

  Widget _stepCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4', style: bodyStyle(size: 13, color: gold, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Consultations & availability', style: displayStyle(size: 32, color: const Color(0xFFF4F1E8))),
        const SizedBox(height: 8),
        Text('Set your fee, how you see patients, and your weekly hours.', style: bodyStyle(size: 15, color: const Color(0xFFC5D0C6))),
      ],
    );
  }

  Widget _hoursForm(bool wide) {
    const fieldFill = Color(0xFF1C2620);
    final decoration = InputDecoration(
      filled: true,
      fillColor: fieldFill,
      hintStyle: bodyStyle(color: const Color(0xFF8C988E)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: nightLine)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide)
          Row(
            children: [
              Expanded(child: _darkField('City', city, decoration)),
              const SizedBox(width: 12),
              Expanded(child: _darkField('State', stateName, decoration)),
              const SizedBox(width: 12),
              Expanded(child: _darkField('Phone', phone, decoration)),
            ],
          )
        else ...[
          _darkField('City', city, decoration),
          const SizedBox(height: 12),
          _darkField('State', stateName, decoration),
          const SizedBox(height: 12),
          _darkField('Phone', phone, decoration),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _darkField('Consultation fee (INR)', fee, decoration)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel('Session length', dark: true),
                  DropdownButtonFormField<int>(
                    value: slotMinutes,
                    dropdownColor: nightRaised,
                    style: bodyStyle(color: Colors.white),
                    decoration: decoration,
                    items: const [30, 45, 60]
                        .map((minutes) => DropdownMenuItem(value: minutes, child: Text('$minutes minutes')))
                        .toList(),
                    onChanged: (value) => setState(() => slotMinutes = value ?? 30),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Consultation modes', style: bodyStyle(size: 14, color: const Color(0xFFE7E2D6), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _mode('In clinic', clinic, () => setState(() => clinic = !clinic)),
            _mode('Video call', video, () => setState(() => video = !video)),
            _mode('Home visit', home, () => setState(() => home = !home)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Weekly availability', style: bodyStyle(size: 14, color: const Color(0xFFE7E2D6), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final entry in days.entries) _dayRow(entry.key, entry.value),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _save,
            style: pillButtonStyle(background: gold, foreground: night),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Submit for review'),
          ),
        ),
      ],
    );
  }

  Widget _darkField(String label, TextEditingController controller, InputDecoration decoration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, dark: true),
        TextField(controller: controller, style: bodyStyle(color: Colors.white), decoration: decoration),
      ],
    );
  }

  Widget _mode(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(selected ? '✓ $label' : label),
      selected: selected,
      showCheckmark: false,
      selectedColor: gold,
      backgroundColor: nightRaised,
      labelStyle: bodyStyle(size: 14, color: selected ? night : const Color(0xFFE7E2D6), weight: FontWeight.w600),
      side: BorderSide(color: selected ? gold : nightLine),
      onSelected: (_) => onTap(),
    );
  }

  Widget _dayRow(String name, _DayHours day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Switch(
            value: day.enabled,
            activeThumbColor: night,
            activeTrackColor: gold,
            onChanged: (value) => setState(() => day.enabled = value),
          ),
          SizedBox(width: 88, child: Text(name, style: bodyStyle(color: day.enabled ? Colors.white : const Color(0xFF8C988E), weight: FontWeight.w600))),
          if (day.enabled) ...[
            _timePill(day.start),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('to', style: bodyStyle(color: const Color(0xFFB7C0B6)))),
            _timePill(day.end),
          ] else
            Text('Unavailable', style: bodyStyle(color: const Color(0xFF8C988E))),
        ],
      ),
    );
  }

  Widget _timePill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: nightRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: nightLine),
      ),
      child: Text(_clock(value), style: bodyStyle(size: 14, color: Colors.white, weight: FontWeight.w600)),
    );
  }

  Future<void> _save() async {
    final amount = num.tryParse(fee.text) ?? 0;
    final rows = [
      for (final entry in days.entries)
        if (entry.value.enabled)
          {
            'weekday': entry.key,
            'start_time': entry.value.start.length == 5 ? '${entry.value.start}:00' : entry.value.start,
            'end_time': entry.value.end.length == 5 ? '${entry.value.end}:00' : entry.value.end,
            'slot_minutes': slotMinutes,
            'allow_clinic': clinic ? 1 : 0,
            'allow_video': video ? 1 : 0,
            'allow_home': home ? 1 : 0,
          },
    ];
    try {
      final repo = ref.read(repositoryProvider);
      await repo.setAvailability(rows);
      await repo.savePractitioner({
        'phone': phone.text.trim(),
        'clinic_address': [city.text.trim(), stateName.text.trim()].where((part) => part.isNotEmpty).join(', '),
        'fee_clinic': clinic ? amount : 0,
        'fee_video': video ? amount : 0,
        'fee_home': home ? amount : 0,
        if (city.text.trim().isNotEmpty) 'regions': [city.text.trim()],
      });
      await repo.submitForReview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted for review')));
      }
    } on ApiException catch (error) {
      if (mounted) await showError(context, error);
    }
  }
}

class PracticeAppointmentsPage extends ConsumerWidget {
  const PracticeAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<AppointmentItem>>(
      future: ref.watch(repositoryProvider).myAppointments(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <AppointmentItem>[];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionTitle('Practice', 'Appointment requests'),
            const SizedBox(height: 12),
            if (rows.isEmpty) const Text('Confirmed visits will appear here.'),
            for (final item in rows)
              Card(
                child: ListTile(
                  title: Text('${item.patientName} · ${item.therapy}'),
                  subtitle: Text('${item.visitType} · ${item.startsOn} · ${item.status}'),
                  onTap: () => context.go('/practice/appointments/${item.name}/note'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotePage extends ConsumerStatefulWidget {
  const NotePage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  final complaint = TextEditingController();
  final observations = TextEditingController();
  final advice = TextEditingController();
  final meeting = TextEditingController();
  final medicines = <Map<String, String>>[
    {'medicine_name': '', 'dose': '', 'frequency': '', 'duration': '', 'anupana': ''},
  ];
  bool share = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visit ${widget.id}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              TextField(controller: meeting, decoration: const InputDecoration(labelText: 'Video meeting link')),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(repositoryProvider).setMeetingUrl(widget.id, meeting.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link saved')));
                  }
                },
                child: const Text('Save meeting link'),
              ),
              const SizedBox(height: 16),
              TextField(controller: complaint, decoration: const InputDecoration(labelText: 'Chief complaint')),
              TextField(controller: observations, decoration: const InputDecoration(labelText: 'Observations'), maxLines: 3),
              TextField(controller: advice, decoration: const InputDecoration(labelText: 'Advice'), maxLines: 3),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: share,
                onChanged: (value) => setState(() => share = value ?? false),
                title: const Text('Share this note with the patient'),
              ),
              const Text('Medicines'),
              for (var i = 0; i < medicines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final field in const [
                        ('medicine_name', 'Medicine'),
                        ('dose', 'Dose'),
                        ('frequency', 'Frequency'),
                        ('duration', 'Duration'),
                        ('anupana', 'Anupana'),
                      ])
                        SizedBox(
                          width: 180,
                          child: TextField(
                            decoration: InputDecoration(labelText: field.$2),
                            onChanged: (value) => medicines[i][field.$1] = value,
                          ),
                        ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => setState(() {
                  medicines.add({'medicine_name': '', 'dose': '', 'frequency': '', 'duration': '', 'anupana': ''});
                }),
                child: const Text('Add medicine'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    final repo = ref.read(repositoryProvider);
                    await repo.saveNote(
                      appointment: widget.id,
                      chiefComplaint: complaint.text.trim(),
                      observations: observations.text.trim(),
                      advice: advice.text.trim(),
                      shareWithPatient: share,
                      submit: true,
                    );
                    final items = medicines.where((row) => (row['medicine_name'] ?? '').isNotEmpty).toList();
                    if (items.isNotEmpty) {
                      await repo.submitPrescription(appointment: widget.id, items: items, advice: advice.text.trim());
                    }
                    await repo.complete(widget.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit record saved')));
                    }
                  } on ApiException catch (error) {
                    if (context.mounted) await showError(context, error);
                  }
                },
                child: const Text('Submit note and prescription'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
