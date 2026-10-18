import 'package:flutter_test/flutter_test.dart';
import 'package:romeu_lanches_admin/core/config/app_environment.dart';

void main() {
  test('sem ENV, o build aponta para local — nunca prod', () {
    expect(AppEnvironment.current, AppEnvironment.local);
    expect(AppEnvironment.current.isProd, isFalse);
  });

  test('wsUrl deriva da baseUrl de cada ambiente', () {
    expect(AppEnvironment.local.wsUrl, 'http://localhost:8080/ws');
    expect(
      AppEnvironment.prod.wsUrl,
      'https://romeu-backend-2ms6.onrender.com/ws',
    );
  });
}
