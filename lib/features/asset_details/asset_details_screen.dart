import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssetDetailsScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailsScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
      ),
      body: Center(
        child: Text('Asset Details $assetId - Coming Soon'),
      ),
    );
  }
}
