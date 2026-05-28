import 'dart:io';
import 'package:flutter/material.dart';

// ============================================================
// CloudStorageProvider — 云存储抽象接口
// ============================================================

enum StorageProviderType { webdav, onedrive, googledrive }

extension StorageProviderTypeX on StorageProviderType {
  String get displayName => switch (this) {
    StorageProviderType.webdav => 'WebDAV',
    StorageProviderType.onedrive => 'OneDrive',
    StorageProviderType.googledrive => 'Google Drive',
  };
  String get chineseName => switch (this) {
    StorageProviderType.webdav => 'WebDAV',
    StorageProviderType.onedrive => '微软 OneDrive',
    StorageProviderType.googledrive => '谷歌 Drive',
  };
  IconData get iconData => switch (this) {
    StorageProviderType.webdav => Icons.cloud_outlined,
    StorageProviderType.onedrive => Icons.cloud_sync_outlined,
    StorageProviderType.googledrive => Icons.cloud_done_outlined,
  };
}

class StorageConfig {
  final StorageProviderType type;
  final String? url;
  final String? username;
  final String? password;
  final String? accessToken;
  const StorageConfig({required this.type, this.url, this.username, this.password, this.accessToken});
}

/// 云存储抽象接口
///
/// 子类职责:
///   1. 管理 OAuth2 token 的获取/刷新/持久化
///   2. 实现文件 CRUD（底层 HTTP 调用）
///   3. 处理 token 过期 → 自动刷新/signOut
abstract class CloudStorage {
  final StorageConfig config;
  CloudStorage(this.config);

  StorageProviderType get type => config.type;

  // ---- 认证 ----
  bool isConfigured();
  Future<bool> authenticate(BuildContext context);
  Future<bool> ensureValidToken();
  Future<bool> testConnection();
  Future<void> signOut();

  // ---- 原子文件操作 ----
  Future<String?> readFile(String remotePath);
  Future<void> writeFile(String remotePath, String content);
  Future<void> uploadFile(String remotePath, File localFile);
  Future<File?> downloadFile(String remotePath, String localPath);
  Future<void> deleteFile(String remotePath);
  Future<void> createDirectory(String remotePath);
  Future<List<String>> listFiles(String remoteDir);

  // ---- 便捷方法 ----
  Future<String?> downloadDataFile() => readFile('youshu/data.json');
  Future<void> uploadDataFile(String jsonString) => writeFile('youshu/data.json', jsonString);
  Future<void> uploadAttachment(File imageFile, String fileName) =>
      uploadFile('youshu/images/$fileName', imageFile);
}
