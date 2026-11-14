import 'package:flutter/foundation.dart';

class SearchItem {
  const SearchItem(this.label);
  final String label;
}

abstract interface class SearchRepository {
  Future<List<SearchItem>> search(String query);
}

class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._repository);
  final SearchRepository _repository;

  int _generation = 0;
  bool _disposed = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<SearchItem> _items = const [];
  List<SearchItem> get items => _items;
  Object? _lastError;
  Object? get lastError => _lastError;

  Future<void> search(String query) async {
    final generation = ++_generation;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _repository.search(query);
      if (!_isCurrent(generation)) return;
      _items = List<SearchItem>.unmodifiable(result);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _lastError = error; // Adapt: map to a UI-safe error.
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
