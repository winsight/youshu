import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/logger.dart';
import 'cloud_storage.dart';

/// OneDrive — 浏览器 OAuth PKCE 流程，拉起微软统一登录页
///
/// Azure 配置: Authentication → Mobile/desktop → Redirect URI: youshuapp://oauth
class OneDriveStorage extends CloudStorage {
  final _storage = const FlutterSecureStorage();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  late final Dio _dio;
  String? _accessToken;

  static const _clientId = '46444e75-5e03-4dfe-bf15-1fd600d1405d';
  static const _tokenKey = 'onedrive_token';
  static const _refreshKey = 'onedrive_refresh';

  OneDriveStorage({required StorageConfig config}) : super(config) {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://graph.microsoft.com/v1.0',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (s) => true,
    ));
  }

  bool isConfigured() => _accessToken != null && _accessToken!.isNotEmpty;

  Future<bool> authenticate(BuildContext context) async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          'youshuapp://oauth',
          scopes: ['Files.ReadWrite', 'offline_access'],
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: 'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize',
            tokenEndpoint: 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token',
          ),
        ),
      );
      if (result == null) {
        _showError(context, '授权被取消');
        return false;
      }
      if (result.accessToken == null) {
        _showError(context, 'Token 获取失败: ${result.tokenAdditionalParameters}');
        return false;
      }

      _accessToken = result.accessToken;
      _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
      await _storage.write(key: _tokenKey, value: _accessToken);
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshKey, value: result.refreshToken);
      }
      AppLogger.info('OneDrive: 登录成功');
      return true;
    } catch (e) {
      _showError(context, '异常: $e');
      return false;
    }
  }

  void _showError(BuildContext context, String msg) {
    AppLogger.error('OneDrive: $msg');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OneDrive: $msg'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<bool> ensureValidToken() async {
    if (_accessToken == null) {
      _accessToken = await _storage.read(key: _tokenKey);
      if (_accessToken != null) _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_accessToken == null) return false;

    final resp = await _dio.get('/me/drive/root?\$select=id');
    if (resp.statusCode == 200) return true;

    final rt = await _storage.read(key: _refreshKey);
    if (rt == null) return false;
    try {
      final result = await _appAuth.token(TokenRequest(
        _clientId, 'youshuapp://oauth', refreshToken: rt,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize',
          tokenEndpoint: 'https://login.microsoftonline.com/consumers/oauth2/v2.0/token',
        ),
      ));
      if (result?.accessToken != null) {
        _accessToken = result!.accessToken;
        _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
        await _storage.write(key: _tokenKey, value: _accessToken);
        if (result.refreshToken != null) await _storage.write(key: _refreshKey, value: result.refreshToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey); await _storage.delete(key: _refreshKey); _accessToken = null;
  }
  Future<bool> testConnection() async =>
      isConfigured() ? (await _dio.get('/me/drive/root?\$select=id')).statusCode == 200 : false;

  Future<void> uploadFile(String remotePath, File localFile) async {
    await _dio.put('/me/drive/root:/youshu/$remotePath:/content',
        data: await localFile.readAsBytes(),
        options: Options(headers: {'Content-Type': 'application/octet-stream'}));
  }
  Future<File?> downloadFile(String remotePath, String localPath) async {
    try {
      final resp = await _dio.get('/me/drive/root:/youshu/$remotePath:/content',
          options: Options(responseType: ResponseType.bytes));
      if (resp.statusCode != 200) return null;
      await File(localPath).writeAsBytes(resp.data); return File(localPath);
    } on DioException { return null; }
  }
  Future<void> deleteFile(String remotePath) async =>
      await _dio.delete('/me/drive/root:/youshu/$remotePath');
  Future<void> createDirectory(String remotePath) async {
    try { await _dio.patch('/me/drive/root:/youshu/$remotePath', data: {'folder': {}}); } catch (_) {}
  }
  Future<List<String>> listFiles(String remoteDir) async {
    try {
      final r = await _dio.get('/me/drive/root:/youshu/$remoteDir:/children?\$select=name');
      return ((r.data?['value'] as List?) ?? []).map((f) => f['name'] as String).toList();
    } on DioException { return []; }
  }
  Future<String?> readFile(String remotePath) async {
    try {
      final r = await _dio.get('/me/drive/root:/youshu/$remotePath:/content',
          options: Options(responseType: ResponseType.plain));
      return r.data?.toString();
    } on DioException { return null; }
  }
  Future<void> writeFile(String remotePath, String content) async {
    await _dio.put('/me/drive/root:/youshu/$remotePath:/content',
        data: content, options: Options(headers: {'Content-Type': 'text/plain'}));
  }
}
