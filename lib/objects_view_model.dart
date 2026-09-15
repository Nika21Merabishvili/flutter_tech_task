import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'object_item.dart';

class ObjectsViewModel extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  List<ObjectItem> _items = const [];

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  List<ObjectItem> get items => _items;

  Future<void> load({bool refresh = false}) async {
    if (_isLoading || (_hasLoaded && !refresh)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = List.unmodifiable(await _client.fetchAll());
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Writes patch the cached list with the server's response instead of
  // refetching: it saves quota, and the shared GET /objects listing doesn't
  // include objects created through the API.
  Future<void> create({
    required String name,
    Map<String, dynamic>? data,
  }) async {
    final created = await _client.create(name: name, data: data);
    _items = List.unmodifiable([created, ..._items]);
    notifyListeners();
  }

  Future<void> update(ObjectItem item) async {
    final updated = await _client.update(item);
    _items = List.unmodifiable([
      for (final existing in _items)
        existing.id == updated.id ? updated : existing,
    ]);
    notifyListeners();
  }
}
