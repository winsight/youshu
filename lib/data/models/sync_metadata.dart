class SyncMetadata {
  final String assetId;
  final int localVersion;
  final int remoteVersion;
  final DateTime lastSyncedAt;

  SyncMetadata({
    required this.assetId,
    this.localVersion = 0,
    this.remoteVersion = 0,
    required this.lastSyncedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'localVersion': localVersion,
      'remoteVersion': remoteVersion,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      assetId: json['assetId'] as String,
      localVersion: json['localVersion'] as int? ?? 0,
      remoteVersion: json['remoteVersion'] as int? ?? 0,
      lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
    );
  }
}
