// O aviso sonoro usa o MCI do Windows via `dart:ffi`, que não existe na web.
// Fora do Windows entra um stub mudo, para o app ainda compilar no Chrome.
export 'new_order_alert_stub.dart'
    if (dart.library.ffi) 'new_order_alert_windows.dart';
