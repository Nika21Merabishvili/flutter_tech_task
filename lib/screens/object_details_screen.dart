import 'package:flutter/material.dart';

import '../object_item.dart';

class ObjectDetailsScreen extends StatelessWidget {
  const ObjectDetailsScreen({super.key, required this.item});

  final ObjectItem item;

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.name, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('ID: ${item.id}', style: textTheme.bodyMedium),
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
