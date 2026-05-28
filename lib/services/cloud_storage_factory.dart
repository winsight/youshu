import 'cloud_storage.dart';
import 'webdav_service.dart';
import 'onedrive_storage.dart';
import 'googledrive_storage.dart';

class CloudStorageFactory {
  static CloudStorage create(StorageConfig config) {
    switch (config.type) {
      case StorageProviderType.webdav:
        return WebDavService(config: config);
      case StorageProviderType.onedrive:
        return OneDriveStorage(config: config);
      case StorageProviderType.googledrive:
        return GoogleDriveStorage(config: config);
    }
  }
}
