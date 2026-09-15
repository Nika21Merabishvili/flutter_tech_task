import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'object_item.dart';

class ObjectsViewModel extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  List<ObjectItem> _items = const [];
  final Set<String> _createdIds = {};

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  List<ObjectItem> get items => _items;

  Future<void> load() async {
    if (_isLoading || _hasLoaded) return;

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

  // Unlike load, a failed refresh keeps the cached list on screen and throws,
  // so the caller can report it. Objects created here are carried over because
  // the listing never returns them.
  Future<void> refresh() async {
    final fetched = await _client.fetchAll();
    final fetchedIds = {for (final item in fetched) item.id};
    _items = List.unmodifiable([
      for (final item in _items)
        if (_createdIds.contains(item.id) && !fetchedIds.contains(item.id))
          item,
      ...fetched,
    ]);
    notifyListeners();
  }

  // Writes patch the cached list with the server's response instead of
  // refetching: it saves quota, and the shared GET /objects listing doesn't
  // include objects created through the API.
  Future<void> create({
    required String name,
    Map<String, dynamic>? data,
  }) async {
    final created = await _client.create(name: name, data: data);
    _createdIds.add(created.id);
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

  // The item leaves the list before the request completes, because a swiped
  // Dismissible must be gone from the tree by the end of its animation. If the
  // API refuses, it goes back where it was and the error is rethrown.
  Future<void> delete(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final removed = _items[index];

    _items = List.unmodifiable([
      for (final item in _items)
        if (item.id != id) item,
    ]);
    notifyListeners();

    try {
      await _client.delete(id);
      _createdIds.remove(id);
    } catch (_) {
      if (!_items.any((item) => item.id == id)) {
        _items = List.unmodifiable(
          [..._items]..insert(index.clamp(0, _items.length), removed),
        );
        notifyListeners();
      }
      rethrow;
    }
  }
}
