import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/utils/logger.dart';

class WebDavConfig {
  final String url;
  final String username;
  final String password;

  WebDavConfig({
    required this.url,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'username': username,
        'password': password,
      };

  factory WebDavConfig.fromJson(Map<String, dynamic> json) => WebDavConfig(
        url: json['url'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
      );
}

class WebDavService {
  final WebDavConfig config;
  late final Dio _dio;

  WebDavService({required this.config}) {
    _dio = Dio(BaseOptions(
      baseUrl: config.url,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
      },
    ));
  }

  Future<bool> testConnection() async {
    try {
      final response = await _dio.request(
        '/',
        options: Options(method: 'PROPFIND'),
      );
      return response.statusCode == 207;
    } catch (e) {
      AppLogger.warn('WebDAV connection test failed: $e');
      return false;
    }
  }

  Future<void> uploadFile(String remotePath, File localFile) async {
    final bytes = await localFile.readAsBytes();
    await _dio.put(
      _normalizePath(remotePath),
      data: bytes,
      options: Options(headers: {'Content-Type': 'application/octet-stream'}),
    );
  }

  Future<File?> downloadFile(String remotePath, String localPath) async {
    try {
      final response = await _dio.get(
        _normalizePath(remotePath),
        options: Options(responseType: ResponseType.bytes),
      );
      final file = File(localPath);
      await file.writeAsBytes(response.data as List<int>);
      return file;
    } catch (e) {
      AppLogger.warn('WebDAV download failed: $e');
      return null;
    }
  }

  Future<void> deleteFile(String remotePath) async {
    await _dio.delete(_normalizePath(remotePath));
  }

  Future<void> createDirectory(String remotePath) async {
    try {
      await _dio.request(
        _normalizePath(remotePath),
        options: Options(method: 'MKCOL'),
      );
    } catch (e) {
      // Directory might already exist, ignore
    }
  }

  Future<List<String>> listFiles(String remoteDir) async {
    try {
      final response = await _dio.request(
        _normalizePath(remoteDir),
        options: Options(
          method: 'PROPFIND',
          headers: {'Depth': '1'},
        ),
      );
      // Simple XML parsing for file list
      final body = response.data as String;
      final hrefs = RegExp(r'<d:href>(.*?)</d:href>')
          .allMatches(body)
          .map((m) => m.group(1)!)
          .where((h) => h != remoteDir && h != '$remoteDir/')
          .toList();
      return hrefs;
    } catch (e) {
      AppLogger.warn('WebDAV list failed: $e');
      return [];
    }
  }

  Future<String?> readFile(String remotePath) async {
    try {
      final response = await _dio.get(
        _normalizePath(remotePath),
        options: Options(responseType: ResponseType.plain),
      );
      return response.data as String;
    } catch (e) {
      return null;
    }
  }

  Future<void> writeFile(String remotePath, String content) async {
    await _dio.put(
      _normalizePath(remotePath),
      data: content,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  String _normalizePath(String path) {
    if (!path.startsWith('/')) return '/$path';
    return path;
  }
}
