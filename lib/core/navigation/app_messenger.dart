import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Aviso disparado de fora de uma view — hoje só o toggle de loja da sidebar,
/// que fica no chrome do app e não pertence a nenhuma tela.
void showAppMessage(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
      backgroundColor: const Color(0xFF2A1F17),
      behavior: SnackBarBehavior.floating,
      width: 420,
    ),
  );
}
