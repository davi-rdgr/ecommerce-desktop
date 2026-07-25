import 'package:flutter/material.dart';

/// Permite navegar de fora da árvore de widgets — usado quando a API devolve
/// 401 e a sessão precisa ser derrubada de onde quer que o app esteja.
final navigatorKey = GlobalKey<NavigatorState>();
