import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

class VaidyaShell extends StatelessWidget {
  const VaidyaShell({
    super.key,
    required this.child,
    required this.signedIn,
    required this.practitioner,
    required this.dark,
    required this.onSignOut,
  });

  final Widget child;
  final bool signedIn;
  final bool practitioner;
  final bool dark;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: dark ? night : cream,
      body: Column(
        children: [
          VaidyaTopBar(signedIn: signedIn, practitioner: practitioner, dark: dark, onSignOut: onSignOut),
          if (!wide)
            VaidyaMobileNavStrip(
              signedIn: signedIn,
              practitioner: practitioner,
              dark: dark,
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Always-visible links on viewports under 900px (desktop uses [VaidyaTopBar]).
class VaidyaMobileNavStrip extends StatelessWidget {
  const VaidyaMobileNavStrip({
    super.key,
    required this.signedIn,
    required this.practitioner,
    required this.dark,
  });

  final bool signedIn;
  final bool practitioner;
  final bool dark;

  List<(String, String)> _links() {
    if (practitioner) {
      return [
        ('Home', '/'),
        ('My profile', '/practice/profile'),
        ('Availability', '/practice/availability'),
        ('Appointments', '/practice/appointments'),
      ];
    }
    if (signedIn) {
      return [
        ('Home', '/'),
        ('Find care', '/practitioners'),
        ('Visits', '/appointments'),
        ('Profile', '/profile'),
        ('Updates', '/notifications'),
      ];
    }
    return [
      ('Home', '/'),
      ('Therapies', '/therapies'),
      ('Find care', '/practitioners'),
      ('For practitioners', '/join'),
    ];
  }

  bool _active(String path, String current) {
    if (path == '/') return current == '/';
    return current == path || current.startsWith('$path/');
  }

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;
    final mutedFg = dark ? const Color(0xFFB7C0B6) : muted;
    final accent = dark ? gold : green;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? night : cream,
        border: Border(bottom: BorderSide(color: dark ? nightLine : line)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final link in _links())
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton(
                  onPressed: () => context.go(link.$2),
                  style: TextButton.styleFrom(
                    foregroundColor: _active(link.$2, current) ? accent : mutedFg,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: bodyStyle(
                      size: 14,
                      weight: _active(link.$2, current) ? FontWeight.w700 : FontWeight.w600,
                      color: _active(link.$2, current) ? accent : mutedFg,
                    ),
                  ),
                  child: Text(link.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VaidyaTopBar extends StatelessWidget {
  const VaidyaTopBar({
    super.key,
    required this.signedIn,
    required this.practitioner,
    required this.dark,
    required this.onSignOut,
  });

  final bool signedIn;
  final bool practitioner;
  final bool dark;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final fg = dark ? const Color(0xFFF4F1E8) : ink;
    return Container(
      color: dark ? night : cream,
      padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: dark ? gold : green, shape: BoxShape.circle),
                  child: Icon(Icons.spa, color: dark ? night : Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Vaidya', style: displayStyle(size: 26, color: fg).copyWith(letterSpacing: -0.4)),
              ],
            ),
          ),
          const Spacer(),
          if (wide) ...[
            _NavLink('How it works', '/', dark: dark),
            _NavLink('Therapies', '/therapies', dark: dark),
            _NavLink('For practitioners', '/join', dark: dark),
            if (signedIn && !practitioner) ...[
              _NavLink('Visits', '/appointments', dark: dark),
              _NavLink('My profile', '/profile', dark: dark),
            ],
            if (practitioner) ...[
              _NavLink('My profile', '/practice/profile', dark: dark),
              _NavLink('Practice', '/practice/appointments', dark: dark),
            ],
            const SizedBox(width: 16),
          ] else if (signedIn)
            IconButton(
              tooltip: practitioner ? 'My profile' : 'Profile',
              onPressed: () => context.go(practitioner ? '/practice/profile' : '/profile'),
              icon: Icon(Icons.person_outline, color: fg),
            ),
          _AccountButton(
            signedIn: signedIn,
            compact: !wide,
            dark: dark,
            onSignOut: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.path, {required this.dark});
  final String label;
  final String path;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: dark ? const Color(0xFFD5DDD4) : const Color(0xFF3E4A42),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: bodyStyle(size: 15, weight: FontWeight.w500, color: ink),
      ),
      child: Text(label),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.signedIn,
    required this.compact,
    required this.dark,
    required this.onSignOut,
  });

  final bool signedIn;
  final bool compact;
  final bool dark;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final label = signedIn ? 'Sign Out' : 'Sign In';
    final icon = signedIn ? Icons.logout : Icons.login;
    final style = TextButton.styleFrom(
      backgroundColor: dark ? gold : green,
      foregroundColor: dark ? night : Colors.white,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 12),
      minimumSize: Size(compact ? 44 : 0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: bodyStyle(size: 14, weight: FontWeight.w600, color: Colors.white),
    );
    if (compact) {
      return TextButton(
        onPressed: _onPress(context),
        style: style,
        child: Icon(icon, size: 18),
      );
    }
    return TextButton.icon(
      onPressed: _onPress(context),
      style: style,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  VoidCallback _onPress(BuildContext context) {
    return () {
      if (signedIn) {
        onSignOut();
        context.go('/');
      } else {
        context.go('/sign-in');
      }
    };
  }
}

class VaidyaFooter extends StatelessWidget {
  const VaidyaFooter({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final bg = dark ? const Color(0xFF0C120E) : const Color(0xFFF7F4EC);
    final fg = dark ? const Color(0xFFE7E2D6) : ink;
    final sub = dark ? const Color(0xFFB7C0B6) : muted;
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: wide ? 340 : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: dark ? gold : green, shape: BoxShape.circle),
                              child: Icon(Icons.spa, size: 15, color: dark ? night : Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text('Vaidya', style: displayStyle(size: 22, color: fg)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Connecting you with verified Ayurveda doctors and therapists in your region. Ancient wisdom, modern convenience.',
                          style: bodyStyle(size: 14, color: sub),
                        ),
                      ],
                    ),
                  ),
                  if (wide) const Spacer(),
                  _FooterCol('Patients', const [('Find a doctor', '/practitioners'), ('Therapies', '/therapies')], fg, sub),
                  SizedBox(width: wide ? 80 : 0, height: wide ? 0 : 16),
                  _FooterCol('Practitioners', const [('Join Vaidya', '/join'), ('Why join', '/join')], fg, sub),
                ],
              ),
              const SizedBox(height: 28),
              Text('© 2026 Vaidya. All rights reserved.', style: bodyStyle(size: 13, color: sub)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  const _FooterCol(this.title, this.links, this.fg, this.sub);
  final String title;
  final List<(String, String)> links;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: bodyStyle(size: 15, color: fg, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final link in links)
          TextButton(
            onPressed: () => context.go(link.$2),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: sub,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(link.$1, style: bodyStyle(size: 14, color: sub)),
            ),
          ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.kicker, this.title, {super.key, this.subtitle});
  final String kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker.toUpperCase(), style: bodyStyle(size: 12, color: sage, weight: FontWeight.w700).copyWith(letterSpacing: 1.4)),
        const SizedBox(height: 8),
        Text(title, style: displayStyle(size: 40)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: bodyStyle()),
        ],
      ],
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: child,
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.dark = false});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: bodyStyle(size: 14, color: dark ? const Color(0xFFE7E2D6) : ink, weight: FontWeight.w600)),
    );
  }
}

Future<void> showError(BuildContext context, Object error) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Please check'),
      content: Text(error.toString()),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}
