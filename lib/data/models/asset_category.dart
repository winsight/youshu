import 'package:flutter/material.dart';

enum AssetCategory {
  electronics,
  transport,
  collection,
  tools,
  other;

  String get displayName {
    switch (this) {
      case AssetCategory.electronics:
        return 'Electronics';
      case AssetCategory.transport:
        return 'Transport';
      case AssetCategory.collection:
        return 'Collection';
      case AssetCategory.tools:
        return 'Tools';
      case AssetCategory.other:
        return 'Other';
    }
  }

  String get chineseName {
    switch (this) {
      case AssetCategory.electronics:
        return '数码';
      case AssetCategory.transport:
        return '交通';
      case AssetCategory.collection:
        return '收藏';
      case AssetCategory.tools:
        return '工具';
      case AssetCategory.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCategory.electronics:
        return Icons.devices;
      case AssetCategory.transport:
        return Icons.directions_car;
      case AssetCategory.collection:
        return Icons.palette;
      case AssetCategory.tools:
        return Icons.build;
      case AssetCategory.other:
        return Icons.category;
    }
  }
}
