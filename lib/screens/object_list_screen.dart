import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../object_item.dart';
import '../objects_view_model.dart';
import 'object_details_screen.dart';
import 'object_edit_screen.dart';

class ObjectListScreen extends StatefulWidget {
  const ObjectListScreen({super.key});

  @override
  State<ObjectListScreen> createState() => _ObjectListScreenState();
}

class _ObjectListScreenState extends State<ObjectListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ObjectsViewModel>().load();
    });
  }

  Future<void> _refresh() async {
    try {
      await context.read<ObjectsViewModel>().refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(ObjectItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ObjectsViewModel>().delete(item.id);
      messenger.showSnackBar(SnackBar(content: Text('Deleted "${item.name}"')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ObjectsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Objects')),
      body: _buildBody(viewModel),
      floatingActionButton: viewModel.hasLoaded
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ObjectEditScreen()),
              ),
              tooltip: 'Add object',
              child: const Icon(Icons.add),
            )
          : null,
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
    if (!viewModel.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = viewModel.items;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [Center(child: Text('No objects yet.'))],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => confirmDelete(context, item),
                  onDismissed: (_) => _delete(item),
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('ID: ${item.id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ObjectDetailsScreen(item: item),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
