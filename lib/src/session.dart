import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'models.dart';
import 'repository.dart';

const defaultApiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8001');

final apiBaseProvider = Provider<String>((ref) => defaultApiBase);

final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

final regionProvider = StateProvider<String?>((ref) => null);

final repositoryProvider = Provider<VaidyaRepository>((ref) {
  final session = ref.watch(sessionProvider).asData?.value;
  return VaidyaRepository(ApiClient(baseUrl: ref.watch(apiBaseProvider), token: session?.token));
});

class SessionController extends AsyncNotifier<Session?> {
  static const _key = 'vaidya_session';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  Future<Session?> build() async {
    try {
      final raw = await storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (session.token.isEmpty) return null;
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> signIn(Session session) async {
    state = AsyncData(session);
    try {
      await storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (_) {}
  }

  Future<void> signOut() async {
    state = const AsyncData(null);
    try {
      await storage.delete(key: _key);
    } catch (_) {}
  }
}
