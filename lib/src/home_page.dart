import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'session.dart';
import 'theme.dart';
import 'widgets.dart';

final homeProvider = FutureProvider<HomeContent>((ref) async {
  final region = ref.watch(regionProvider);
  try {
    return await ref.watch(repositoryProvider).home(region);
  } catch (_) {
    return HomeContent.fallback();
  }
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    return home.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const HomeView(content: null),
      data: (content) => HomeView(content: content),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.content});
  final HomeContent? content;

  @override
  Widget build(BuildContext context) {
    final data = content ?? HomeContent.fallback();
    return SingleChildScrollView(
      child: Column(
        children: [
          _Hero(data: data),
          _TherapiesBand(therapies: data.therapies),
          const _GrowPractice(),
          if (data.testimonials.isNotEmpty) _Stories(items: data.testimonials),
          const VaidyaFooter(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data});
  final HomeContent data;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final hero = data.block('home_hero');
    final title = hero?.title ?? 'Healing rooted in ancient wisdom, close to home.';
    final body = hero?.body ??
        'Find trusted Ayurveda doctors and Panchakarma therapists in your region. Compare profiles, check availability, and book your consultation in minutes.';
    final copy = Padding(
      padding: EdgeInsets.fromLTRB(wide ? 8 : 4, wide ? 28 : 12, wide ? 28 : 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E1D4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 16, color: green),
                const SizedBox(width: 6),
                Text('Verified Ayurveda practitioners', style: bodyStyle(size: 13, color: const Color(0xFF3E4A42), weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _WisdomTitle(title, size: wide ? 62 : 42),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(body, style: bodyStyle(size: 16)),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/practitioners'),
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('Find practitioners near me'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/join'),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Join as a practitioner  →'),
              ),
            ],
          ),
        ],
      ),
    );
    final portrait = SizedBox(
      width: wide ? 460 : double.infinity,
      height: wide ? 520 : 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: _ArchClipper(),
              child: Image.asset('assets/hero_still.jpg', fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 6))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Color(0xFFFFF3D6), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: Color(0xFFE0A020), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Care in your region', style: bodyStyle(size: 13, color: ink, weight: FontWeight.w700)),
                      Text('Doctors & therapists nearby', style: bodyStyle(size: 12, color: muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.85, -0.7),
          radius: 1.15,
          colors: [creamGlow, cream],
        ),
      ),
      padding: EdgeInsets.fromLTRB(wide ? 48 : 20, wide ? 18 : 8, wide ? 48 : 20, wide ? 28 : 8),
      child: PageFrame(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: copy),
                  portrait,
                ],
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 12), portrait]),
      ),
    );
  }
}

class _WisdomTitle extends StatelessWidget {
  const _WisdomTitle(this.title, {required this.size});
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    const phrase = 'ancient wisdom';
    final index = title.toLowerCase().indexOf(phrase);
    if (index < 0) {
      return Text(title, style: displayStyle(size: size));
    }
    return Text.rich(
      TextSpan(
        style: displayStyle(size: size),
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(text: title.substring(index, index + phrase.length), style: displayStyle(size: size, style: FontStyle.italic)),
          TextSpan(text: title.substring(index + phrase.length)),
        ],
      ),
    );
  }
}

class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final radius = size.width / 2;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TherapiesBand extends StatelessWidget {
  const _TherapiesBand({required this.therapies});
  final List<Therapy> therapies;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Holistic treatments\nfor body, mind\nand spirit', style: displayStyle(size: wide ? 48 : 36, color: const Color(0xFFF7F3EA))),
        const SizedBox(height: 16),
        Text(
          'From classical Panchakarma to everyday wellness consultations, find specialists for the care you need.',
          style: bodyStyle(size: 16, color: const Color(0xFFD7E6DC)),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset('assets/shirodhara.jpg', height: wide ? 250 : 200, width: double.infinity, fit: BoxFit.cover),
        ),
      ],
    );
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 520 ? 2 : 1;
        final width = (constraints.maxWidth - (cols - 1) * 14) / cols;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final therapy in therapies) SizedBox(width: width, child: _TherapyCard(therapy)),
          ],
        );
      },
    );
    return Container(
      color: forest,
      padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 20, vertical: wide ? 64 : 36),
      child: PageFrame(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: intro),
                  const SizedBox(width: 36),
                  Expanded(flex: 6, child: grid),
                ],
              )
            : Column(children: [intro, const SizedBox(height: 20), grid]),
      ),
    );
  }
}

class _TherapyCard extends StatelessWidget {
  const _TherapyCard(this.therapy);
  final Therapy therapy;

  IconData get _icon {
    switch (therapy.name) {
      case 'Panchakarma':
        return Icons.water_drop_outlined;
      case 'Abhyanga':
        return Icons.back_hand_outlined;
      case 'Shirodhara':
        return Icons.wb_sunny_outlined;
      case 'Herbal medicine':
        return Icons.eco_outlined;
      case 'Diet & lifestyle':
        return Icons.restaurant_outlined;
      default:
        return Icons.monitor_heart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: forestCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3E8664)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(_icon, color: const Color(0xFFE7F3EA), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(therapy.name, style: bodyStyle(size: 16, color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(therapy.summary, style: bodyStyle(size: 13, color: const Color(0xFFD5E6DB))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowPractice extends StatelessWidget {
  const _GrowPractice();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Container(
      color: cream,
      padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 20, vertical: 56),
      child: PageFrame(
        child: Container(
          padding: EdgeInsets.all(wide ? 36 : 20),
          decoration: BoxDecoration(color: const Color(0xFFF8F4EA), borderRadius: BorderRadius.circular(28)),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _GrowCopy(wide: wide)),
                    const SizedBox(width: 28),
                    const Expanded(child: _GrowPoints()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GrowCopy(wide: wide),
                    const SizedBox(height: 20),
                    const _GrowPoints(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GrowCopy extends StatelessWidget {
  const _GrowCopy({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FOR DOCTORS & THERAPISTS', style: bodyStyle(size: 12, color: sage, weight: FontWeight.w700).copyWith(letterSpacing: 1.3)),
        const SizedBox(height: 10),
        Text('Grow your Ayurveda practice with Vaidya', style: displayStyle(size: wide ? 40 : 32)),
      ],
    );
  }
}

class _GrowPoints extends StatelessWidget {
  const _GrowPoints();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PracticePoint(Icons.groups_outlined, 'Reach patients actively looking for care in your region'),
        SizedBox(height: 12),
        _PracticePoint(Icons.calendar_month_outlined, 'Manage your availability and appointment requests'),
      ],
    );
  }
}

class _PracticePoint extends StatelessWidget {
  const _PracticePoint(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: bodyStyle(size: 15, color: ink, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Stories extends StatelessWidget {
  const _Stories({required this.items});
  final List<Testimonial> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cream,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: PageFrame(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${'★' * item.rating} “${item.quote}”', style: bodyStyle(size: 14)),
                    Text(item.displayName, style: bodyStyle(size: 14, color: ink, weight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TherapiesPage extends ConsumerWidget {
  const TherapiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    return home.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (content) => ListView(
        padding: EdgeInsets.zero,
        children: [
          _TherapiesBand(therapies: content.therapies),
          const VaidyaFooter(),
        ],
      ),
    );
  }
}
