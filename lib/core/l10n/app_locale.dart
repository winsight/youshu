import 'package:flutter/material.dart';

enum AppLanguage {
  system,
  en,
  zh;

  String get displayName {
    switch (this) {
      case AppLanguage.system:
        return '跟随系统';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.zh:
        return '中文';
    }
  }

  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.zh:
        return const Locale('zh');
    }
  }
}

class AppL10n {
  final Locale locale;

  AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  bool get isZh => locale.languageCode == 'zh';

  String get assetOverview => isZh ? '资产概览' : 'Asset Overview';
  String get totalValue => isZh ? '总价值' : 'Total Value';
  String get dailyAvg => isZh ? '每日成本' : 'Daily Cost';
  String get inService => isZh ? '使用中' : 'In Service';
  String get retired => isZh ? '已退役' : 'Retired';
  String get sold => isZh ? '已出售' : 'Sold';
  String get all => isZh ? '全部' : 'All';
  String get active => isZh ? '使用中' : 'Active';
  String get assets => isZh ? '资产' : 'Assets';
  String get trends => isZh ? '趋势' : 'Trends';
  String get settings => isZh ? '设置' : 'Settings';
  String get newAsset => isZh ? '新增资产' : 'New Asset';
  String get editAsset => isZh ? '编辑资产' : 'Edit Asset';
  String get assetDetails => isZh ? '资产详情' : 'Asset Details';
  String get save => isZh ? '保存' : 'Save';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get delete => isZh ? '删除' : 'Delete';
  String get edit => isZh ? '编辑' : 'Edit';
  String get sell => isZh ? '出售' : 'Sell';
  String get retire => isZh ? '退役' : 'Retire';
  String get help => isZh ? '帮助' : 'Help';

  // Add Asset
  String get uploadPhoto => isZh ? '上传或拍照' : 'Upload or Take Photo';
  String get chooseFromGallery => isZh ? '从相册选择' : 'Choose from Gallery';
  String get takePhoto => isZh ? '拍照' : 'Take Photo';
  String get cropImage => isZh ? '裁剪图片' : 'Crop Image';
  String get done => isZh ? '完成' : 'Done';
  String get assetName => isZh ? '资产名称' : 'Asset Name';
  String get category => isZh ? '分类' : 'Category';
  String get purchasePrice => isZh ? '购买价格' : 'Purchase Price';
  String get purchaseDate => isZh ? '购买日期' : 'Purchase Date';
  String get notes => isZh ? '备注（可选）' : 'Notes (Optional)';
  String get markInService => isZh ? '标记为使用中' : 'Mark as In Service';
  String get saveAsset => isZh ? '保存资产' : 'Save Asset';
  String get updateAsset => isZh ? '更新资产' : 'Update Asset';
  String get saving => isZh ? '保存中...' : 'Saving...';
  String get assetSaved => isZh ? '资产已保存' : 'Asset saved';
  String get assetUpdated => isZh ? '资产已更新' : 'Asset updated';

  // Details
  String get originalCost => isZh ? '原始成本' : 'Original Cost';
  String get dailyCost => isZh ? '每日成本' : 'Daily Cost';
  String get serviceLife => isZh ? '使用寿命' : 'Service Life';
  String get daysUsed => isZh ? '已使用天数' : 'Days Used';
  String get goal => isZh ? '目标' : 'Goal';
  String get estDepreciation => isZh ? '预计折旧' : 'Est. Depreciation';
  String get resaleValue => isZh ? '残值' : 'Resale Value';
  String get valueTrend => isZh ? '价值趋势' : 'Value Trend';
  String get purchaseSpecs => isZh ? '购买规格' : 'Purchase Specs';
  String get merchant => isZh ? '商家' : 'Merchant';
  String get warranty => isZh ? '保修' : 'Warranty';
  String get goalAchieved => isZh ? '已达成' : 'Goal achieved';
  String get daysLeft => isZh ? '剩余天数' : 'days left';
  String get started => isZh ? '开始于' : 'Started';
  String get completed => isZh ? '已完成' : 'Completed';
  String get nameRequired => isZh ? '名称不能为空' : 'Name is required';
  String get priceRequired => isZh ? '价格不能为空' : 'Price is required';
  String get priceInvalid => isZh ? '价格格式无效' : 'Invalid price';

  // Statistics
  String get portfolio => isZh ? '资产组合' : 'Portfolio';
  String get assetDistribution => isZh ? '资产分布' : 'Asset Distribution';
  String get portfolioLiquidity => isZh ? '组合流动性' : 'Portfolio Liquidity';
  String get averageDailyCost => isZh ? '日均成本' : 'Average Daily Cost';
  String get noAssets => isZh ? '暂无资产' : 'No assets yet';
  String get addFirstAsset =>
      isZh ? '点击 + 添加你的第一个资产' : 'Tap + to add your first asset';
  String get addAsset => isZh ? '添加资产' : 'Add Asset';

  // Settings
  String get webdavSync => isZh ? 'WebDAV 同步' : 'WebDAV Sync';
  String get webdavDesc => isZh
      ? '配置 WebDAV 服务器实现云端同步\n（支持 Nextcloud、Synology 等）'
      : 'Configure WebDAV server for cloud sync\n(Nextcloud, Synology, etc.)';
  String get webdavUrl => isZh ? 'WebDAV 地址' : 'WebDAV URL';
  String get username => isZh ? '用户名' : 'Username';
  String get password => isZh ? '密码' : 'Password';
  String get testConnection => isZh ? '测试连接' : 'Test Connection';
  String get saveConfig => isZh ? '保存配置' : 'Save Config';
  String get syncStatus => isZh ? '同步状态' : 'Sync Status';
  String get configured => isZh ? '已配置' : 'Configured';
  String get notConfigured => isZh ? '未配置' : 'Not configured';
  String get syncNow => isZh ? '立即同步' : 'Sync Now';
  String get syncing => isZh ? '同步中...' : 'Syncing...';
  String get connectionSuccess => isZh ? '连接成功！' : 'Connection successful!';
  String get connectionFailed => isZh ? '连接失败' : 'Connection failed';
  String get configSaved => isZh ? '配置已保存' : 'Configuration saved';
  String get syncComplete => isZh ? '同步完成' : 'Sync complete';
  String get syncFailed => isZh ? '同步失败' : 'Sync failed';
  String get fillAllFields => isZh ? '请填写所有字段' : 'Please fill all fields';

  // Language
  String get language => isZh ? '语言' : 'Language';
  String get appearance => isZh ? '外观' : 'Appearance';
  String get themeSystem => isZh ? '跟随系统' : 'System';
  String get themeLight => isZh ? '浅色模式' : 'Light';
  String get themeDark => isZh ? '深色模式' : 'Dark';

  // About
  String get about => isZh ? '关于' : 'About';
  String get appName => isZh ? '应用名称' : 'App Name';
  String get version => isZh ? '版本' : 'Version';
  String get dataStorage => isZh ? '数据存储' : 'Data Storage';
  String get storageValue => isZh ? '本地 + WebDAV 同步' : 'Local + WebDAV Sync';

  // Delete
  String get deleteAsset => isZh ? '删除资产' : 'Delete Asset';
  String get deleteConfirm =>
      isZh ? '此操作不可撤销，确定删除吗？' : 'This cannot be undone. Are you sure?';
  String get assetNotFound => isZh ? '资产未找到' : 'Asset not found';
  String get backgroundRemoved => isZh ? '背景已去除' : 'Background removed';
  String get backgroundRemoveFailed =>
      isZh ? '背景去除失败' : 'Background removal failed';
  String get removeBackground => isZh ? '去除背景' : 'Remove Background';

  // Select category
  String get selectCategory => isZh ? '选择分类' : 'Select category';

  // Device
  String get electronics => isZh ? '数码' : 'Electronics';
  String get transport => isZh ? '交通' : 'Transport';
  String get collection => isZh ? '收藏' : 'Collection';
  String get tools => isZh ? '工具' : 'Tools';
  String get other => isZh ? '其他' : 'Other';

  String getCategoryName(dynamic category) {
    final name = category?.toString() ?? '';
    if (name.contains('electronics')) return electronics;
    if (name.contains('transport')) return transport;
    if (name.contains('collection')) return collection;
    if (name.contains('tools')) return tools;
    return other;
  }
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(covariant _AppL10nDelegate old) => false;
}
