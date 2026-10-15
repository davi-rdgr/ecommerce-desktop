/// Substituto de [NewOrderAlert] em plataformas sem `dart:ffi` (web): não
/// toca nada.
class NewOrderAlert {
  NewOrderAlert._();

  static Future<NewOrderAlert> open() async => NewOrderAlert._();

  void play() {}
}
