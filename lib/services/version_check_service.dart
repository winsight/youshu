import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  static const _versionUrl =
      'https://raw.githubusercontent.com/winsight/youshu/master/version.json';

  final Dio _dio = Dio();

  /// 返回 null = 无需更新，非 null = 有新版本
  /// 注意：网络异常会抛 [VersionCheckException]，调用方应区分处理
  Future<UpdateInfo?> checkUpdate() async {
    final resp = await _dio.get(_versionUrl,
        options: Options(responseType: ResponseType.plain));
    if (resp.statusCode != 200) {
      throw VersionCheckException('服务器返回 ${resp.statusCode}');
    }

    final json = jsonDecode(resp.data as String) as Map<String, dynamic>;
    final remoteVersion = json['versionCode'] as int;
    final versionName = json['versionName'] as String;
    final releaseNote = json['releaseNote'] as String;
    final forceUpdate = json['forceUpdate'] as bool;
    final updateUrl = json['updateUrl'] as String;

    final info = await PackageInfo.fromPlatform();
    // buildNumber = Android versionCode, iOS CFBundleVersion
    final localVersion = int.tryParse(info.buildNumber) ?? 0;

    if (remoteVersion > localVersion) {
      return UpdateInfo(
        versionName: versionName,
        versionCode: remoteVersion,
        releaseNote: releaseNote,
        forceUpdate: forceUpdate,
        updateUrl: updateUrl,
      );
    }
    return null;
  }
}

class VersionCheckException implements Exception {
  final String message;
  VersionCheckException(this.message);
  @override
  String toString() => message;
}

class UpdateInfo {
  final String versionName;
  final int versionCode;
  final String releaseNote;
  final bool forceUpdate;
  final String updateUrl;

  UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.releaseNote,
    required this.forceUpdate,
    required this.updateUrl,
  });
}
