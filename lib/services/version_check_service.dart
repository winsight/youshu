import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 基于 GitHub version.json 的版本更新检测服务
class VersionCheckService {
  static const _versionUrl =
      'https://raw.githubusercontent.com/winsight/youshu/master/version.json';

  final Dio _dio = Dio();

  /// 返回 null 表示无需更新，否则返回远程版本信息
  Future<UpdateInfo?> checkUpdate() async {
    try {
      final resp = await _dio.get(_versionUrl,
          options: Options(responseType: ResponseType.plain));
      if (resp.statusCode != 200) return null;

      final json = jsonDecode(resp.data as String) as Map<String, dynamic>;
      final remoteVersion = json['versionCode'] as int;
      final versionName = json['versionName'] as String;
      final releaseNote = json['releaseNote'] as String;
      final forceUpdate = json['forceUpdate'] as bool;
      final updateUrl = json['updateUrl'] as String;

      final info = await PackageInfo.fromPlatform();
      final localVersion = int.tryParse(info.buildNumber) ?? 1;

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
    } catch (_) {
      return null; // 网络异常等，静默跳过
    }
  }
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
