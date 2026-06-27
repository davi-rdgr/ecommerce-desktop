import 'package:flutter/foundation.dart';

class ScaffoldController extends ChangeNotifier {
  int _pageIndex = 0;
  int _pendingOrdersCount = 0;
  bool _isStoreOpen = true;

  int get pageIndex => _pageIndex;
  int get pendingOrdersCount => _pendingOrdersCount;
  bool get isStoreOpen => _isStoreOpen;

  void goTo(int index) {
    if (_pageIndex == index) return;
    _pageIndex = index;
    notifyListeners();
  }

  void setPendingOrdersCount(int count) {
    if (_pendingOrdersCount == count) return;
    _pendingOrdersCount = count;
    notifyListeners();
  }

  void toggleStore() {
    _isStoreOpen = !_isStoreOpen;
    notifyListeners();
  }
}
