import 'package:flutter/foundation.dart';

class FavoriteStore extends ChangeNotifier {
  FavoriteStore({Set<String>? initialSymbols})
    : _symbols =
          initialSymbols ?? {'005930', '000660', '035720', '247540', '373220'};

  final Set<String> _symbols;

  Set<String> get symbols => Set.unmodifiable(_symbols);

  bool contains(String symbol) {
    return _symbols.contains(symbol);
  }

  void toggle(String symbol) {
    if (_symbols.contains(symbol)) {
      _symbols.remove(symbol);
    } else {
      _symbols.add(symbol);
    }

    notifyListeners();
  }

  void add(String symbol) {
    if (_symbols.add(symbol)) {
      notifyListeners();
    }
  }

  void remove(String symbol) {
    if (_symbols.remove(symbol)) {
      notifyListeners();
    }
  }
}
