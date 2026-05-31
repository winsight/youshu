import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/version_check_service.dart';

Future<void> checkAndShowUpdate(BuildContext context) async {
  try {
    final service = VersionCheckService();
    final info = await service.checkUpdate();
    if (!context.mounted) return;

    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已是最新版本'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => AlertDialog(
        title: Text('发现新版本 ${info.versionName}'),
        content: SingleChildScrollView(child: Text(info.releaseNote)),
        actions: [
          if (!info.forceUpdate)
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('稍后')),
          FilledButton(
            onPressed: () => launchUrl(Uri.parse(info.updateUrl)),
            child: const Text('去更新'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查更新失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
