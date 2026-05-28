import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart';
import 'cloud_storage.dart';

class WebDavException implements Exception {
  final String message;
  final int? statusCode;
  WebDavException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class WebDavService extends CloudStorage {
  late final Dio _dio;
  late final String _basePath;

  WebDavService({required StorageConfig config})
      : super(config) {
    final uri = Uri.parse(config.url!);
    _basePath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';

    _dio = Dio(BaseOptions(
      baseUrl: '${uri.scheme}://${uri.host}',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
      },
      validateStatus: (status) => true,
    ));
  }

  @override
  bool isConfigured() => config.url != null && config.url!.isNotEmpty;

  @override
  Future<bool> authenticate(BuildContext context) async => isConfigured();

  @override
  Future<bool> ensureValidToken() async => isConfigured();

  @override
  Future<void> signOut() async {}

  String? _parseXmlError(String xml) {
    final msgMatch = RegExp(r'<s:message>(.*?)</s:message>', caseSensitive: false)
        .firstMatch(xml);
    final excMatch = RegExp(r'<s:exception>(.*?)</s:exception>', caseSensitive: false)
        .firstMatch(xml);
    if (msgMatch != null) {
      final msg = msgMatch.group(1)!;
      final exc = excMatch?.group(1);
      return exc != null ? '$exc: $msg' : msg;
    }
    return null;
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.request(
        _basePath,
        options: Options(method: 'PROPFIND', headers: {'Depth': '0'}),
      );
      if (response.statusCode != 207) return false;

      await _mkcol('${_basePath}youshu');
      await _mkcol('${_basePath}youshu/data');
      await _mkcol('${_basePath}youshu/images');
      return true;
    } catch (e) {
      AppLogger.warn('WebDAV connection test failed: $e');
      return false;
    }
  }

  @override
  Future<void> uploadFile(String remotePath, File localFile) async {
    final bytes = await localFile.readAsBytes();
    final fullPath = _basePath + remotePath;
    final response = await _dio.put(
      fullPath,
      data: bytes,
      options: Options(headers: {'Content-Type': 'application/octet-stream'}),
    );

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      final body = response.data?.toString() ?? '';
      final errMsg = _parseXmlError(body) ?? 'HTTP ${response.statusCode}';
      throw WebDavException(errMsg, statusCode: response.statusCode);
    }
  }

  @override
  Future<File?> downloadFile(String remotePath, String localPath) async {
    try {
      final fullPath = _basePath + remotePath;
      final response = await _dio.get(
        fullPath,
        options: Options(responseType: ResponseType.bytes),
      );
      final file = File(localPath);
      await file.writeAsBytes(response.data as List<int>);
      return file;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      AppLogger.warn('WebDAV download failed ($remotePath): $e');
      return null;
    }
  }

  @override
  Future<void> deleteFile(String remotePath) async {
    await _dio.delete(_basePath + remotePath);
  }

  @override
  Future<void> createDirectory(String remotePath) async {
    await _mkcol('${_basePath}$remotePath');
  }

  Future<void> _mkcol(String fullPath) async {
    try {
      await _dio.request(fullPath, options: Options(method: 'MKCOL'));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 405) return; // already exists
      if (code == 409 && fullPath.contains('/')) {
        final parent = fullPath.substring(0, fullPath.lastIndexOf('/'));
        await _mkcol(parent);
        await _mkcol(fullPath);
        return;
      }
    }
  }

  @override
  Future<List<String>> listFiles(String remoteDir) async {
    try {
      final dirPath = '$_basePath$remoteDir'.endsWith('/')
          ? '$_basePath$remoteDir'
          : '$_basePath$remoteDir/';
      final response = await _dio.request(
        dirPath,
        options: Options(method: 'PROPFIND', headers: {'Depth': '1'}),
      );

      final body = response.data;
      if (body is! String) return [];

      final hrefRegex = RegExp(r'<[^>]*:?href[^>]*>(.*?)</[^>]*:?href>',
          caseSensitive: false, dotAll: true);
      final hrefs = <String>[];
      for (final match in hrefRegex.allMatches(body)) {
        var href = match.group(1)?.trim() ?? '';
        if (href.isEmpty) continue;
        href = Uri.decodeFull(href);
        if (href == dirPath || href.endsWith('/')) continue;
        hrefs.add(href);
      }
      return hrefs;
    } on DioException {
      return [];
    }
  }

  @override
  Future<String?> readFile(String remotePath) async {
    try {
      final response = await _dio.get(
        _basePath + remotePath,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data as String?;
    } on DioException {
      return null;
    }
  }

  @override
  Future<void> writeFile(String remotePath, String content) async {
    final fullPath = _basePath + remotePath;
    final response = await _dio.put(
      fullPath,
      data: content,
      options: Options(headers: {'Content-Type': 'application/json; charset=utf-8'}),
    );

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      final body = response.data?.toString() ?? '';
      final errMsg = _parseXmlError(body) ?? 'HTTP ${response.statusCode}';
      throw WebDavException(errMsg, statusCode: response.statusCode);
    }
  }
}
