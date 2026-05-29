import 'asset_status.dart';

class Asset {
  /// 全局唯一标识符 (UUID v4)
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final DateTime purchaseDate;
  final AssetStatus status;
  final int goalDays;
  final String? imagePath;
  final String? stickerImagePath;
  final String? notes;
  final String? merchant;
  final String? warranty;
  final DateTime createdAt;

  /// 毫秒级 UTC 时间戳 — 每次修改或删除时必须更新
  final DateTime updatedAt;

  /// 软删除标记，默认为 false。严禁物理删除同步数据
  final bool isDeleted;

  /// 本地乐观锁版本号（仅本地使用，不参与云端合并）
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
    this.stickerImagePath,
    this.notes,
    this.merchant,
    this.warranty,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncVersion = 0,
  });

  // ---- 计算属性 ----
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
    String? category,
    double? purchasePrice,
    DateTime? purchaseDate,
    AssetStatus? status,
    int? goalDays,
    String? imagePath,
    String? stickerImagePath,
    String? notes,
    String? merchant,
    String? warranty,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
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
      stickerImagePath: stickerImagePath ?? this.stickerImagePath,
      notes: notes ?? this.notes,
      merchant: merchant ?? this.merchant,
      warranty: warranty ?? this.warranty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  /// 序列化为同步 JSON —— updatedAt 输出为毫秒级 UTC 时间戳
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'status': status.name,
      'goalDays': goalDays,
      // 仅输出文件名，不暴露设备本地绝对路径
      'imagePath': imagePath != null ? imagePath!.split('/').last : null,
      'stickerImagePath': stickerImagePath != null ? stickerImagePath!.split('/').last : null,
      'notes': notes,
      'merchant': merchant,
      'warranty': warranty,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }

  /// 从同步 JSON 反序列化 —— updatedAt 支持 int (毫秒戳) 与 String (ISO8601) 两种格式
  factory Asset.fromJson(Map<String, dynamic> json) {
    DateTime parseUpdatedAt(dynamic v) {
      if (v is int) {
        return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
      }
      if (v is String) {
        return DateTime.parse(v);
      }
      return DateTime.now().toUtc();
    }

    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'other',
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      status: AssetStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AssetStatus.inService,
      ),
      goalDays: json['goalDays'] as int? ?? 1095,
      imagePath: json['imagePath'] as String?,
      stickerImagePath: json['stickerImagePath'] as String?,
      notes: json['notes'] as String?,
      merchant: json['merchant'] as String?,
      warranty: json['warranty'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: parseUpdatedAt(json['updatedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
      syncVersion: json['syncVersion'] as int? ?? 0,
    );
  }
}
