import 'package:flutter/material.dart';

/// Transição padrão entre as telas de fora do shell (splash → login → app).
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 400),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);
