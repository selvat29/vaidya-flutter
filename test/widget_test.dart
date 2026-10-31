import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaidya/main.dart';
import 'package:vaidya/src/api_client.dart';
import 'package:vaidya/src/models.dart';
import 'package:vaidya/src/repository.dart';
import 'package:vaidya/src/router.dart';
import 'package:vaidya/src/session.dart';

class FakeRepository extends VaidyaRepository {
  FakeRepository() : super(ApiClient(baseUrl: 'http://127.0.0.1:9'));

  @override
  Future<HomeContent> home(String? region) async => HomeContent.fallback();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('home shows the Vaidya story, therapies, and a testimonial', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 4200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
        child: const VaidyaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Vaidya'), findsWidgets);
    expect(find.textContaining('ancient wisdom'), findsOneWidget);
    expect(find.text('Panchakarma'), findsWidgets);
    expect(find.textContaining('Meera Nair'), findsWidgets);
    expect(find.text('Find practitioners near me'), findsOneWidget);
  });

  testWidgets('guest visits are redirected to sign in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
        child: const VaidyaApp(),
      ),
    );
    await tester.pump();
    final context = tester.element(find.text('Vaidya').first);
    final container = ProviderScope.containerOf(context);
    container.read(routerProvider).go('/appointments');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Send code'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
  });
}
