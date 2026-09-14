import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objects_view_model.dart';

class ObjectListScreen extends StatefulWidget {
  const ObjectListScreen({super.key});

  @override
  State<ObjectListScreen> createState() => _ObjectListScreenState();
}

class _ObjectListScreenState extends State<ObjectListScreen> {
  @override
  void initState() {
    super.initState();
    // load() notifies listeners synchronously, which would throw if it ran
    // while the first frame is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ObjectsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ObjectsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Objects')),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(ObjectsViewModel viewModel) {
    final error = viewModel.error;

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => viewModel.load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    // Covers the first frame, before the post-frame load() has started.
    if (!viewModel.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.items.isEmpty) {
      return const Center(child: Text('No objects yet.'));
    }

    final items = viewModel.items;
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('ID: ${item.id}'),
        );
      },
    );
  }
}
