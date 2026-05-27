import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  final String? editAssetId;

  const AddAssetScreen({super.key, this.editAssetId});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editAssetId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Asset' : 'New Asset'),
      ),
      body: const Center(
        child: Text('Add Asset - Coming Soon'),
      ),
    );
  }
}
