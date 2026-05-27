enum AssetStatus {
  inService,
  retired,
  sold;

  String get displayName {
    switch (this) {
      case AssetStatus.inService:
        return 'In Service';
      case AssetStatus.retired:
        return 'Retired';
      case AssetStatus.sold:
        return 'Sold';
    }
  }

  String get chineseName {
    switch (this) {
      case AssetStatus.inService:
        return '使用中';
      case AssetStatus.retired:
        return '已退役';
      case AssetStatus.sold:
        return '已出售';
    }
  }
}
