import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:romeu_lanches_admin/core/auth/saved_session.dart';

String _jwt(Map<String, dynamic> payload) {
  String part(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(payload)}.assinatura';
}

void main() {
  final now = DateTime(2026, 10, 18, 20);
  int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  test('token com exp no futuro não está vencido', () {
    final token = _jwt({'exp': epoch(now.add(const Duration(days: 29)))});
    expect(SavedSession.isExpired(token, now: now), isFalse);
  });

  test('token com exp no passado está vencido', () {
    final token = _jwt({'exp': epoch(now.subtract(const Duration(minutes: 1)))});
    expect(SavedSession.isExpired(token, now: now), isTrue);
  });

  test('token ilegível ou sem exp conta como vencido', () {
    expect(SavedSession.isExpired('lixo', now: now), isTrue);
    expect(SavedSession.isExpired(_jwt({'sub': 'x'}), now: now), isTrue);
  });
}
