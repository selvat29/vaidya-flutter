import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'api_client.dart';
import 'home_page.dart';
import 'models.dart';
import 'session.dart';
import 'theme.dart';
import 'widgets.dart';

class PractitionersPage extends ConsumerStatefulWidget {
  const PractitionersPage({super.key});

  @override
  ConsumerState<PractitionersPage> createState() => _PractitionersPageState();
}

class _PractitionersPageState extends ConsumerState<PractitionersPage> {
  String? therapy;
  String? visitType;
  late Future<List<PractitionerCard>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<PractitionerCard>> _load() {
    final region = ref.read(regionProvider) ?? 'Kochi';
    return ref.read(repositoryProvider).search(region: region, therapy: therapy, visitType: visitType);
  }

  void _reload() => setState(() => future = _load());

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(regionProvider) ?? 'Kochi';
    final therapies = ref.watch(homeProvider).asData?.value.therapies ?? const <Therapy>[];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Care in your region', 'Doctors and therapists in $region'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DropdownButton<String?>(
                    value: therapy,
                    hint: const Text('All therapies'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All therapies')),
                      for (final item in therapies) DropdownMenuItem(value: item.name, child: Text(item.name)),
                    ],
                    onChanged: (value) {
                      therapy = value;
                      _reload();
                    },
                  ),
                  DropdownButton<String?>(
                    value: visitType,
                    hint: const Text('Any visit'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any visit')),
                      DropdownMenuItem(value: 'Clinic', child: Text('Clinic')),
                      DropdownMenuItem(value: 'Video', child: Text('Video')),
                      DropdownMenuItem(value: 'Home', child: Text('Home')),
                    ],
                    onChanged: (value) {
                      visitType = value;
                      _reload();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<PractitionerCard>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  final rows = snapshot.data ?? const [];
                  if (rows.isEmpty) return const Text('No verified practitioners in this region yet.');
                  return Column(
                    children: [
                      for (final row in rows)
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(row.practitionerName, style: Theme.of(context).textTheme.titleLarge),
                            subtitle: Text(
                              '${row.practitionerType} · ${row.therapies.join(', ')}\nClinic ₹${row.fees['clinic']?.toStringAsFixed(0)} · Video ₹${row.fees['video']?.toStringAsFixed(0)} · Home ₹${row.fees['home']?.toStringAsFixed(0)}',
                            ),
                            trailing: row.ratingCount > 0 ? Text('${row.ratingAverage.toStringAsFixed(1)} ★') : null,
                            onTap: () => context.go('/practitioners/${row.name}'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PractitionerDetailPage extends ConsumerStatefulWidget {
  const PractitionerDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PractitionerDetailPage> createState() => _PractitionerDetailPageState();
}

class _PractitionerDetailPageState extends ConsumerState<PractitionerDetailPage> {
  String visitType = 'Clinic';
  DateTime day = DateTime.now().add(const Duration(days: 1));
  String? therapy;
  Slot? slot;
  bool consent = false;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(repositoryProvider).profile(widget.id);
    return FutureBuilder<PractitionerCard>(
      future: profile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doctor = snapshot.data!;
        therapy ??= doctor.therapies.isEmpty ? null : doctor.therapies.first;
        final date = DateFormat('yyyy-MM-dd').format(day);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.practitionerName, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('${doctor.practitionerType} · ${doctor.qualifications}'),
                  const SizedBox(height: 8),
                  Text(doctor.bio),
                  if (doctor.clinicAddress.isNotEmpty) Text(doctor.clinicAddress),
                  const SizedBox(height: 8),
                  Text('Clinic ₹${doctor.fees['clinic']?.toStringAsFixed(0)} · Video ₹${doctor.fees['video']?.toStringAsFixed(0)} · Home ₹${doctor.fees['home']?.toStringAsFixed(0)}'),
                  const SizedBox(height: 20),
                  if (doctor.testimonials.isNotEmpty) TestimonialList(items: doctor.testimonials),
                  const Divider(),
                  const SectionTitle('Book', 'Choose a visit'),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: visitType,
                    items: const [
                      DropdownMenuItem(value: 'Clinic', child: Text('Clinic')),
                      DropdownMenuItem(value: 'Video', child: Text('Video')),
                      DropdownMenuItem(value: 'Home', child: Text('Home')),
                    ],
                    onChanged: (value) => setState(() {
                      visitType = value ?? 'Clinic';
                      slot = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: therapy,
                    items: doctor.therapies.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: (value) => setState(() => therapy = value),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        initialDate: day,
                      );
                      if (picked != null) setState(() => day = picked);
                    },
                    child: Text(DateFormat('EEE, d MMM').format(day)),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Slot>>(
                    future: ref.read(repositoryProvider).slots(doctor.name, date, visitType),
                    builder: (context, slots) {
                      final rows = slots.data ?? const <Slot>[];
                      if (rows.isEmpty) return const Text('No open slots for this day.');
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in rows)
                            ChoiceChip(
                              label: Text(item.start.substring(11, 16)),
                              selected: slot?.start == item.start,
                              onSelected: (_) => setState(() => slot = item),
                            ),
                        ],
                      );
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: consent,
                    onChanged: (value) => setState(() => consent = value ?? false),
                    title: const Text(
                      'I consent to this consultation and to sharing my name, age, contact details, and the reason for the visit with this practitioner.',
                    ),
                  ),
                  FilledButton(
                    onPressed: busy ? null : () => _book(doctor),
                    child: Text(busy ? 'Booking…' : 'Continue to payment'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _book(PractitionerCard doctor) async {
    final session = ref.read(sessionProvider).asData?.value;
    if (session == null || !session.isPatient) {
      if (mounted) context.go('/sign-in');
      return;
    }
    if (slot == null || therapy == null || !consent) {
      await showError(context, 'Choose a therapy, a time, and accept the consent line.');
      return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      final appointment = await repo.book(
        practitioner: doctor.name,
        therapy: therapy!,
        visitType: visitType,
        startsOn: slot!.start,
      );
      final order = await repo.createOrder(appointment.name);
      if (!mounted) return;
      if (order.devMode) {
        await repo.markPaidDev(appointment.name);
        if (!mounted) return;
        context.go('/appointments/${appointment.name}');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment started'),
          content: Text('Razorpay order ${order.orderId} for ₹${(order.amount / 100).toStringAsFixed(0)} is ready. Complete it with key ${order.keyId}.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } on ApiException catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class TestimonialList extends StatelessWidget {
  const TestimonialList({super.key, required this.items});
  final List<Testimonial> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('“${item.quote}”'),
            subtitle: Text('${item.displayName} · ${'★' * item.rating}'),
          ),
      ],
    );
  }
}
