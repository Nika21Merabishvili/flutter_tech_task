import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../object_item.dart';
import '../objects_view_model.dart';

class ObjectEditScreen extends StatefulWidget {
  const ObjectEditScreen({super.key, this.item});

  final ObjectItem? item;

  @override
  State<ObjectEditScreen> createState() => _ObjectEditScreenState();
}

class _ObjectEditScreenState extends State<ObjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final List<_FieldPair> _fields = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name);
    item?.data?.forEach((key, value) {
      _fields.add(_FieldPair(key: key, value: '$value'));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() => _fields.add(_FieldPair()));
  }

  void _removeField(_FieldPair field) {
    setState(() => _fields.remove(field));
    // The row's text fields keep these controllers until the rebuild finishes,
    // so disposing them right away would use them after disposal.
    WidgetsBinding.instance.addPostFrameCallback((_) => field.dispose());
  }

  String? _validateKey(_FieldPair field) {
    final key = field.keyController.text.trim();
    if (key.isEmpty) {
      return field.valueController.text.isEmpty ? null : 'Key is required';
    }
    final count = _fields
        .where((other) => other.keyController.text.trim() == key)
        .length;
    return count > 1 ? 'Duplicate key' : null;
  }

  Map<String, dynamic>? _buildData() {
    final original = widget.item?.data ?? const <String, dynamic>{};
    final data = <String, dynamic>{};
    for (final field in _fields) {
      final key = field.keyController.text.trim();
      final value = field.valueController.text;
      if (key.isEmpty && value.isEmpty) continue;
      // Values are edited as text. One left untouched keeps its original value,
      // so saving doesn't turn numbers, booleans or nested objects into strings.
      final unchanged =
          original.containsKey(key) && '${original[key]}' == value;
      data[key] = unchanged ? original[key] : value;
    }
    return data.isEmpty ? null : data;
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final viewModel = context.read<ObjectsViewModel>();
    final item = widget.item;
    final name = _nameController.text.trim();
    final data = _buildData();

    setState(() => _isSaving = true);
    try {
      if (item == null) {
        await viewModel.create(name: name, data: data);
      } else {
        await viewModel.update(ObjectItem(id: item.id, name: name, data: data));
      }
      if (!mounted) return;
      // The messenger belongs to the app, so the SnackBar outlives this route
      // and shows on the screen underneath.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item == null ? 'Created "$name"' : 'Saved "$name"'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'New object' : 'Edit object'),
      ),
      // A Column rather than a lazy ListView, so every row is built and
      // validated on save, including rows scrolled off screen.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 24),
              Text('Data', style: Theme.of(context).textTheme.titleMedium),
              for (final field in _fields)
                _FieldPairRow(
                  key: ObjectKey(field),
                  field: field,
                  keyValidator: (_) => _validateKey(field),
                  onRemove: _isSaving ? null : () => _removeField(field),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isSaving ? null : _addField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add field'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldPair {
  _FieldPair({String? key, String? value})
    : keyController = TextEditingController(text: key),
      valueController = TextEditingController(text: value);

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _FieldPairRow extends StatelessWidget {
  const _FieldPairRow({
    super.key,
    required this.field,
    required this.keyValidator,
    required this.onRemove,
  });

  final _FieldPair field;
  final FormFieldValidator<String> keyValidator;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: field.keyController,
              decoration: const InputDecoration(labelText: 'Key'),
              validator: keyValidator,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: field.valueController,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove field',
          ),
        ],
      ),
    );
  }
}
