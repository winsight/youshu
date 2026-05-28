import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/utils/logger.dart';
import 'cloud_storage.dart';

/// Google Drive — 使用 google_sign_in 原生登录（App 内拉取账户选择器）
class GoogleDriveStorage extends CloudStorage {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'gdrive_token';

  late final GoogleSignIn _googleSignIn;
  late final Dio _dio;
  String? _accessToken;

  String? _youshuFolderId, _dataFolderId, _imagesFolderId;

  GoogleDriveStorage({required StorageConfig config}) : super(config) {
    _googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/drive.file'],
    );
    _dio = Dio(BaseOptions(
      baseUrl: 'https://www.googleapis.com/drive/v3',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (s) => true,
    ));
  }

  // ======== 认证 ========

  @override
  bool isConfigured() => _accessToken != null && _accessToken!.isNotEmpty;

  @override
  Future<bool> authenticate(BuildContext context) async {
    try {
      // 先尝试静默登录
      var account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        AppLogger.warn('Google: 用户取消');
        return false;
      }

      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token == null) {
        AppLogger.warn('Google: accessToken 为空');
        return false;
      }

      _accessToken = token;
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _storage.write(key: _tokenKey, value: token);
      AppLogger.info('Google: 登录成功 (${account.email})');
      return true;
    } catch (e, stack) {
      AppLogger.error('Google login error: $e\n$stack');
      return false;
    }
  }

  @override
  Future<bool> ensureValidToken() async {
    // 1. 从安全存储加载（工厂创建新实例时用）
    if (_accessToken == null) {
      _accessToken = await _storage.read(key: _tokenKey);
      if (_accessToken != null) {
        _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
      }
    }
    if (_accessToken == null) return false;

    // 2. 校验
    final resp = await _dio.get('/files', queryParameters: {'pageSize': 1});
    if (resp.statusCode == 200) return true;

    // 3. 过期 → 尝试静默刷新
    if (await _googleSignIn.isSignedIn()) {
      final account = _googleSignIn.currentUser;
      if (account != null) {
        try {
          final auth = await account.authentication;
          if (auth.accessToken != null) {
            _accessToken = auth.accessToken;
            _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
            await _storage.write(key: _tokenKey, value: _accessToken);
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _tokenKey);
    _accessToken = null;
  }

  @override
  Future<bool> testConnection() async =>
      isConfigured() ? (await _dio.get('/files', queryParameters: {'pageSize': 1})).statusCode == 200 : false;

  // ======== 文件夹 ========

  Future<void> _ensureFolders() async {
    _youshuFolderId ??= await _findOrCreateFolder('youshu');
    _dataFolderId ??= await _findOrCreateFolder('data', _youshuFolderId);
    _imagesFolderId ??= await _findOrCreateFolder('images', _youshuFolderId);
  }

  Future<String?> _findOrCreateFolder(String name, [String? parentId]) async {
    final qParts = ["name='$name'", "mimeType='application/vnd.google-apps.folder'", "trashed=false"];
    if (parentId != null) qParts.add("'$parentId' in parents");
    final search = await _dio.get('/files', queryParameters: {'q': qParts.join(' and '), 'fields': 'files(id)'});
    if (search.statusCode == 200 && (search.data['files'] as List?)?.isNotEmpty == true) {
      return (search.data['files'] as List).first['id'] as String;
    }
    final body = <String, dynamic>{'name': name, 'mimeType': 'application/vnd.google-apps.folder'};
    if (parentId != null) body['parents'] = [parentId];
    final create = await _dio.post('/files', data: jsonEncode(body));
    return create.data?['id'] as String?;
  }

  String? _parentIdFor(String path) => path.startsWith('images/') ? _imagesFolderId : _dataFolderId;

  Future<String?> _findFileId(String name, String? pid) async {
    final q = "name='$name' and '$pid' in parents and trashed=false";
    final r = await _dio.get('/files', queryParameters: {'q': q, 'fields': 'files(id)'});
    return (r.statusCode == 200 && (r.data['files'] as List?)?.isNotEmpty == true)
        ? (r.data['files'] as List).first['id'] as String : null;
  }

  // ======== 文件操作 ========

  @override
  Future<void> uploadFile(String remotePath, File localFile) async {
    await _ensureFolders();
    final bytes = await localFile.readAsBytes();
    final name = remotePath.split('/').last;
    final pid = _parentIdFor(remotePath);
    final existingId = await _findFileId(name, pid);

    if (existingId != null) {
      await _dio.patch('https://www.googleapis.com/upload/drive/v3/files/$existingId?uploadType=media',
          data: bytes, options: Options(headers: {'Content-Type': 'application/octet-stream'}));
    } else {
      await _dio.post('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        data: FormData.fromMap({
          'metadata': MultipartFile.fromString(jsonEncode({'name': name, 'parents': [pid]})),
          'file': MultipartFile.fromBytes(bytes, filename: name),
        }),
      );
    }
  }

  @override
  Future<File?> downloadFile(String remotePath, String localPath) async {
    try {
      await _ensureFolders();
      final fileId = await _findFileId(remotePath.split('/').last, _parentIdFor(remotePath));
      if (fileId == null) return null;
      final resp = await _dio.get('/files/$fileId', queryParameters: {'alt': 'media'},
          options: Options(responseType: ResponseType.bytes));
      if (resp.statusCode != 200) return null;
      await File(localPath).writeAsBytes(resp.data);
      return File(localPath);
    } on DioException { return null; }
  }

  @override
  Future<void> deleteFile(String remotePath) async {
    await _ensureFolders();
    final fileId = await _findFileId(remotePath.split('/').last, _parentIdFor(remotePath));
    if (fileId != null) await _dio.delete('/files/$fileId');
  }

  @override Future<void> createDirectory(String _) async => await _ensureFolders();

  @override
  Future<List<String>> listFiles(String remoteDir) async {
    try {
      await _ensureFolders();
      final pid = remoteDir.startsWith('images/') ? _imagesFolderId : _dataFolderId;
      final r = await _dio.get('/files', queryParameters: {'q': "'$pid' in parents and trashed=false", 'fields': 'files(name)'});
      return ((r.data?['files'] as List?) ?? []).map((f) => f['name'] as String).toList();
    } on DioException { return []; }
  }

  @override
  Future<String?> readFile(String remotePath) async {
    try {
      await _ensureFolders();
      final fileId = await _findFileId(remotePath.split('/').last, _parentIdFor(remotePath));
      if (fileId == null) return null;
      final r = await _dio.get('/files/$fileId', queryParameters: {'alt': 'media'},
          options: Options(responseType: ResponseType.plain));
      return r.data?.toString();
    } on DioException { return null; }
  }

  @override
  Future<void> writeFile(String remotePath, String content) async {
    await _ensureFolders();
    final name = remotePath.split('/').last;
    final pid = _parentIdFor(remotePath);
    final existingId = await _findFileId(name, pid);
    if (existingId != null) {
      await _dio.patch('https://www.googleapis.com/upload/drive/v3/files/$existingId?uploadType=media',
          data: content, options: Options(headers: {'Content-Type': 'text/plain'}));
    } else {
      await _dio.post('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        data: FormData.fromMap({
          'metadata': MultipartFile.fromString(jsonEncode({'name': name, 'parents': [pid]})),
          'file': MultipartFile.fromString(content, filename: name),
        }),
      );
    }
  }
}
