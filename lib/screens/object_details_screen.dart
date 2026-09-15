import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../object_item.dart';
import '../objects_view_model.dart';
import 'object_edit_screen.dart';

Future<bool> confirmDelete(BuildContext context, ObjectItem item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete object?'),
      content: Text('"${item.name}" will be permanently deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class ObjectDetailsScreen extends StatefulWidget {
  const ObjectDetailsScreen({super.key, required this.item});

  final ObjectItem item;

  @override
  State<ObjectDetailsScreen> createState() => _ObjectDetailsScreenState();
}

class _ObjectDetailsScreenState extends State<ObjectDetailsScreen> {
  late ObjectItem _current = widget.item;
  bool _isDeleting = false;

  Future<void> _delete() async {
    if (_isDeleting || !await confirmDelete(context, _current)) return;
    if (!mounted) return;

    final viewModel = context.read<ObjectsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final item = _current;

    setState(() => _isDeleting = true);
    try {
      await viewModel.delete(item.id);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Deleted "${item.name}"')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // A save replaces the cached entry, so show the latest copy rather than
    // the one passed in when this screen was opened. The last copy seen is the
    // fallback, since a pending delete takes the entry out of the list.
    final current = _current = context.select<ObjectsViewModel, ObjectItem>(
      (viewModel) => viewModel.items.firstWhere(
        (candidate) => candidate.id == widget.item.id,
        orElse: () => _current,
      ),
    );
    final data = current.data;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            onPressed: _isDeleting
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ObjectEditScreen(item: current),
                    ),
                  ),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: _isDeleting ? null : _delete,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(current.name, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('ID: ${current.id}', style: textTheme.bodyMedium),
          const Divider(height: 32),
          if (data == null || data.isEmpty)
            const Text('No additional data.')
          else
            for (final entry in data.entries)
              _DataRow(label: entry.key, value: entry.value),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text('$value')),
        ],
      ),
    );
  }
}
