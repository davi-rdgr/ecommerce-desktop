import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';

/// Aviso sonoro de pedido novo, tocado pelo winmm do próprio Windows.
///
/// Não entra pacote de áudio para isso: quem toca é o **MCI**, a interface de
/// mídia que já vem no Windows, via `mciSendString`. É ela — e não o
/// `PlaySound`, que só aceita WAV PCM — que dá conta de mp3.
///
/// O preço do MCI é precisar de um arquivo em disco: asset do Flutter vive
/// empacotado, então [open] copia o mp3 para a pasta temporária do sistema uma
/// vez, na subida, e abre o dispositivo apontando para essa cópia.
///
/// Trocar o som é trocar o arquivo em `assets/sounds/notificacao.mp3`.
class NewOrderAlert {
  static const _asset = 'assets/sounds/notificacao.mp3';

  /// Apelido do dispositivo MCI. Precisa ser único no processo — é por ele
  /// que o `play` sabe o que tocar.
  static const _alias = 'romeu_alerta_pedido';

  /// `false` quando o mp3 não pôde ser preparado: [play] cai no beep do
  /// sistema em vez de ficar mandando comando para um alias que não existe.
  bool _ready = false;

  NewOrderAlert._();

  /// Prepara o som. Chamar uma vez, na subida do app: extrair o asset e abrir
  /// o dispositivo custa I/O, e no meio do pico isso atrasaria justamente o
  /// aviso. Depois daqui, tocar é uma linha de comando para o MCI.
  static Future<NewOrderAlert> open() async {
    final alert = NewOrderAlert._();

    try {
      final data = await rootBundle.load(_asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      final dir = Directory.systemTemp.path;
      final file = File('$dir${Platform.pathSeparator}$_alias.mp3');
      try {
        await file.writeAsBytes(bytes, flush: true);
      } on FileSystemException {
        // Outra instância do painel pode estar com o arquivo aberto no MCI.
        // A cópia que já está lá serve — é o mesmo asset.
        if (!file.existsSync()) rethrow;
      }

      // `type mpegvideo` é o dispositivo MCI que decodifica mp3. Sem ele, o
      // MCI tenta adivinhar pelo registro e falha em máquina com associação
      // de .mp3 trocada.
      final result = _mci('open "${file.path}" type mpegvideo alias $_alias');
      alert._ready = result == 0;
    } catch (_) {
      // Asset faltando, disco cheio, codec ausente: nada disso pode impedir o
      // app de subir. Avisar mal é melhor que não avisar.
    }

    return alert;
  }

  /// Toca o aviso. Nunca lança: som é acessório, o painel não pode cair no
  /// meio do movimento por causa de um mp3.
  void play() {
    try {
      // `from 0` rebobina antes de tocar — sem isso, o segundo pedido pegaria
      // o arquivo parado no fim e não sairia som nenhum. Numa rajada, o efeito
      // é o toque recomeçar, em vez de cinco avisos sobrepostos.
      if (_ready && _mci('play $_alias from 0') == 0) return;

      // Sem codec, sem placa de som utilizável ou dispositivo perdido: ainda
      // dá para arrancar o beep padrão do Windows.
      MessageBeep(MB_ICONASTERISK);
    } catch (_) {}
  }

  /// Manda um comando ao MCI. Devolve 0 no sucesso, ou o código de erro.
  static int _mci(String command) => using((arena) {
    final native = PCWSTR(command.toNativeUtf16(allocator: arena));
    return mciSendString(native, null, 0, null);
  });
}
