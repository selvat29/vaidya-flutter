import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/url_strategy_stub.dart' if (dart.library.html) 'package:flutter_web_plugins/url_strategy.dart';

import 'src/router.dart';
import 'src/theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: VaidyaApp()));
}

class VaidyaApp extends ConsumerWidget {
  const VaidyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vaidya',
      debugShowCheckedModeBanner: false,
      theme: vaidyaTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
