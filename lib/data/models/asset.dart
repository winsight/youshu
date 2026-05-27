import 'asset_status.dart';
import 'asset_category.dart';

class Asset {
  final String id;
  final String name;
  final AssetCategory category;
  final double purchasePrice;
  final DateTime purchaseDate;
  final AssetStatus status;
  final int goalDays;
  final String? imagePath;
  final String? notes;
  final String? merchant;
  final String? warranty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncVersion;

  Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.purchaseDate,
    this.status = AssetStatus.inService,
    this.goalDays = 1095,
    this.imagePath,
    this.notes,
    this.merchant,
    this.warranty,
    required this.createdAt,
    required this.updatedAt,
    this.syncVersion = 0,
  });

  // Computed properties
  int get daysUsed {
    final now = DateTime.now();
    final diff = now.difference(purchaseDate).inDays;
    return diff > 0 ? diff : 1;
  }

  double get dailyCost => purchasePrice / daysUsed;

  double get progressRatio => (daysUsed / goalDays).clamp(0.0, 1.0);

  int get daysLeft => (goalDays - daysUsed).clamp(0, goalDays);

  double get depreciation => purchasePrice * progressRatio;

  double get resaleValue => purchasePrice - depreciation;

  bool get goalAchieved => daysUsed >= goalDays;

  Asset copyWith({
    String? id,
    String? name,
    AssetCategory? category,
    double? purchasePrice,
    DateTime? purchaseDate,
    AssetStatus? status,
    int? goalDays,
    String? imagePath,
    String? notes,
    String? merchant,
    String? warranty,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncVersion,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
      goalDays: goalDays ?? this.goalDays,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      merchant: merchant ?? this.merchant,
      warranty: warranty ?? this.warranty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'status': status.name,
      'goalDays': goalDays,
      'imagePath': imagePath,
      'notes': notes,
      'merchant': merchant,
      'warranty': warranty,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncVersion': syncVersion,
    };
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      category: AssetCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AssetCategory.other,
      ),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      status: AssetStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AssetStatus.inService,
      ),
      goalDays: json['goalDays'] as int? ?? 1095,
      imagePath: json['imagePath'] as String?,
      notes: json['notes'] as String?,
      merchant: json['merchant'] as String?,
      warranty: json['warranty'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncVersion: json['syncVersion'] as int? ?? 0,
    );
  }
}
