import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final String nameZh;
  final String iconName;
  final int sortOrder;

  const CategoryInfo({
    required this.name,
    required this.nameZh,
    this.iconName = 'category',
    this.sortOrder = 0,
  });

  IconData get icon => _iconMap[iconName] ?? Icons.category;

  static IconData iconFor(String iconName) {
    return _iconMap[iconName] ?? Icons.category;
  }

  static final _iconMap = <String, IconData>{
    'devices': Icons.devices,
    'directions_car': Icons.directions_car,
    'palette': Icons.palette,
    'build': Icons.build,
    'category': Icons.category,
    'phone_android': Icons.phone_android,
    'computer': Icons.computer,
    'camera_alt': Icons.camera_alt,
    'headphones': Icons.headphones,
    'watch': Icons.watch,
    'tv': Icons.tv,
    'videogame_asset': Icons.videogame_asset,
    'book': Icons.book,
    'chair': Icons.chair,
    'kitchen': Icons.kitchen,
    'checkroom': Icons.checkroom,
    'sports_esports': Icons.sports_esports,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'flight': Icons.flight,
    'local_offer': Icons.local_offer,
    'star': Icons.star,
    'inventory_2': Icons.inventory_2,
  };

  static const List<String> availableIcons = [
    'devices', 'phone_android', 'computer', 'camera_alt', 'headphones',
    'watch', 'tv', 'videogame_asset',
    'directions_car', 'flight',
    'palette', 'book', 'brush', 'music_note',
    'build', 'kitchen', 'chair', 'checkroom',
    'sports_esports', 'fitness_center', 'pets',
    'local_offer', 'star', 'inventory_2', 'category',
  ];
}
