import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'home_page.dart';
import 'models.dart';
import 'session.dart';
import 'widgets.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, this.role = 'Patient'});
  final String role;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  late String role = widget.role;
  final phone = TextEditingController();
  final name = TextEditingController();
  final otp = TextEditingController();
  String? devOtp;
  bool sent = false;
  bool busy = false;

  @override
  void dispose() {
    phone.dispose();
    name.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageFrame(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role == 'Practitioner' ? 'Join as a practitioner' : 'Sign in', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('We will text a 6-digit code to your mobile number.'),
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Patient', label: Text('Patient')),
                    ButtonSegment(value: 'Practitioner', label: Text('Practitioner')),
                  ],
                  selected: {role},
                  onSelectionChanged: (value) => setState(() => role = value.first),
                ),
                const SizedBox(height: 16),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name')),
                const SizedBox(height: 12),
                if (sent) ...[
                  TextField(controller: otp, decoration: const InputDecoration(labelText: 'Code')),
                  if (devOtp != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Developer code: $devOtp')),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: Text(sent ? 'Verify and continue' : 'Send code'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      if (!sent) {
        final response = await repo.sendOtp(phone.text.trim(), role);
        setState(() {
          sent = true;
          devOtp = response['dev_otp']?.toString();
        });
      } else {
        final session = await repo.verifyOtp(
          phone: phone.text.trim(),
          otp: otp.text.trim(),
          role: role,
          fullName: name.text.trim(),
        );
        await ref.read(sessionProvider.notifier).signIn(session);
        if (!mounted) return;
        context.go(session.isPractitioner ? '/practice/profile' : '/');
      }
    } on ApiException catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class AppointmentsPage extends ConsumerWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(repositoryProvider).myAppointments();
    return FutureBuilder<List<AppointmentItem>>(
      future: future,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <AppointmentItem>[];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const PageFrame(child: SectionTitle('Your care', 'Appointments')),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (rows.isEmpty)
              const PageFrame(child: Text('No appointments yet.'))
            else
              PageFrame(
                child: Column(
                  children: [
                    for (final item in rows)
                      Card(
                        child: ListTile(
                          title: Text('${item.therapy} with ${item.practitionerName}'),
                          subtitle: Text('${item.visitType} · ${item.startsOn} · ${item.status}'),
                          onTap: () => context.go('/appointments/${item.name}'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class AppointmentDetailPage extends ConsumerWidget {
  const AppointmentDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(repositoryProvider).clinicalFor(id);
    final appointments = ref.watch(repositoryProvider).myAppointments();
    return FutureBuilder(
      future: Future.wait([appointments, record]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final visits = snapshot.data![0] as List<AppointmentItem>;
        final clinical = snapshot.data![1] as ClinicalRecord;
        final match = visits.where((item) => item.name == id).toList();
        if (match.isEmpty) return const Center(child: Text('Appointment not found.'));
        final item = match.first;
        final prescription = clinical.prescription;
        final note = clinical.note;
        final items = prescription?['items'] as List? ?? const [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.therapy, style: Theme.of(context).textTheme.headlineMedium),
                  Text('${item.practitionerName} · ${item.visitType}'),
                  Text(item.startsOn),
                  Text(item.status),
                  if ((item.meetingUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText('Video link: ${item.meetingUrl}'),
                  ],
                  const SizedBox(height: 16),
                  if (item.status == 'Pending Payment' || item.status == 'Confirmed')
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(repositoryProvider).cancel(item.name);
                        if (context.mounted) context.go('/appointments');
                      },
                      child: const Text('Cancel appointment'),
                    ),
                  if (note != null) ...[
                    const SizedBox(height: 24),
                    const SectionTitle('Visit note', 'Shared with you'),
                    Text(note['chief_complaint']?.toString() ?? ''),
                    Text(note['advice']?.toString() ?? ''),
                  ],
                  if (prescription != null) ...[
                    const SizedBox(height: 24),
                    const SectionTitle('Prescription', 'From your practitioner'),
                    Text('${prescription['practitioner_name']} · ${prescription['qualification']}'),
                    Text('Registration ${prescription['registration_number']}'),
                    Text('${prescription['patient_name']}, ${prescription['patient_age'] ?? ''} ${prescription['patient_gender'] ?? ''}'),
                    const SizedBox(height: 8),
                    for (final row in items)
                      if (row is Map)
                        Text('${row['medicine_name']} · ${row['dose'] ?? ''} · ${row['frequency'] ?? ''} · ${row['duration'] ?? ''} · ${row['anupana'] ?? ''}'),
                    if ((prescription['advice'] ?? '').toString().isNotEmpty) Text(prescription['advice'].toString()),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class PatientProfilePage extends ConsumerStatefulWidget {
  const PatientProfilePage({super.key});

  @override
  ConsumerState<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends ConsumerState<PatientProfilePage> {
  late final TextEditingController name;
  late final TextEditingController address;
  String? gender;

  @override
  void initState() {
    super.initState();
    final patient = ref.read(sessionProvider).asData?.value?.patient;
    name = TextEditingController(text: patient?['patient_name']?.toString() ?? '');
    address = TextEditingController(text: patient?['address']?.toString() ?? '');
    gender = patient?['gender']?.toString();
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).asData?.value;
    final regions = ref.watch(homeProvider).asData?.value.regions ?? const <Region>[];
    final region = ref.watch(regionProvider) ?? session?.patient?['region']?.toString();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Account', 'Your profile'),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: regions.any((item) => item.name == region) ? region : null,
                hint: const Text('Region'),
                items: regions.map((item) => DropdownMenuItem(value: item.name, child: Text(item.name))).toList(),
                onChanged: (value) => ref.read(regionProvider.notifier).state = value,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: gender?.isEmpty ?? true ? null : gender,
                hint: const Text('Gender'),
                items: const ['Female', 'Male', 'Other', 'Prefer not to say']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => gender = value),
              ),
              const SizedBox(height: 12),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await ref.read(repositoryProvider).savePatient({
                    'patient_name': name.text.trim(),
                    'region': ref.read(regionProvider),
                    'gender': gender,
                    'address': address.text.trim(),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
                  }
                },
                child: const Text('Save profile'),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).signOut();
                  if (context.mounted) context.go('/');
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final notificationsProvider = FutureProvider((ref) => ref.watch(repositoryProvider).notifications());

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notificationsProvider);
    return notes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (rows) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionTitle('Updates', 'Notifications'),
          const SizedBox(height: 12),
          if (rows.isEmpty) const Text('Confirmations and prescriptions will show up here.'),
          for (final row in rows)
            Card(
              child: ListTile(title: Text(row.subject), subtitle: Text(row.message)),
            ),
        ],
      ),
    );
  }
}
