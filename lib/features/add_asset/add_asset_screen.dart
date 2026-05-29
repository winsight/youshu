import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_status.dart';
import '../../data/models/category_model.dart';
import '../../providers/database_provider.dart';
import '../../providers/asset_providers.dart';
import '../../services/background_removal/removal_facade.dart';
import '../../core/l10n/app_locale.dart';
import '../../shared/widgets/add_category_dialog.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  final String? editAssetId;

  const AddAssetScreen({super.key, this.editAssetId});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _merchantController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _customCategoryController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  String _category = 'electronics';
  AssetStatus _status = AssetStatus.inService;
  File? _imageFile;
  bool _isSaving = false;
  bool _isRemovingBg = false;

  bool get _isEditing => widget.editAssetId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    final asset = await ref
        .read(assetRepositoryProvider)
        .getAssetById(widget.editAssetId!);
    if (asset != null && mounted) {
      setState(() {
        _nameController.text = asset.name;
        _priceController.text = asset.purchasePrice.toStringAsFixed(2);
        _notesController.text = asset.notes ?? '';
        _merchantController.text = asset.merchant ?? '';
        _warrantyController.text = asset.warranty ?? '';
        _purchaseDate = asset.purchaseDate;
        _category = asset.category;
        _status = asset.status;
        if (asset.imagePath != null) {
          _imageFile = File(asset.imagePath!);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _merchantController.dispose();
    _warrantyController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _removeBackground() async {
    if (_imageFile == null) return;

    setState(() => _isRemovingBg = true);
    try {
      final facade = BackgroundRemovalFacade();
      final result = await facade.removeBackground(_imageFile!);
      setState(() => _imageFile = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).backgroundRemoved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppL10n.of(context).backgroundRemoveFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemovingBg = false);
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final price = double.tryParse(_priceController.text) ?? 0;
      final now = DateTime.now();
      final id = _isEditing ? widget.editAssetId! : generateId();

      String? imagePath = _imageFile?.path;
      if (_imageFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${appDir.path}/images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        final ext = _imageFile!.path.split('.').last;
        final destPath = '${imageDir.path}/$id.$ext';
        // Copy if the file isn't already in the target location
        if (_imageFile!.path != destPath) {
          await _imageFile!.copy(destPath);
        }
        imagePath = destPath;
      }

      final asset = Asset(
        id: id,
        name: _nameController.text.trim(),
        category: _category,
        purchasePrice: price,
        purchaseDate: _purchaseDate,
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
        warranty: _warrantyController.text.trim().isEmpty
            ? null
            : _warrantyController.text.trim(),
        imagePath: imagePath,
        stickerImagePath: _imageFile?.path.contains('_sticker') == true ? imagePath : null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(assetRepositoryProvider).upsertAsset(asset);

      // Invalidate providers for auto-refresh
      ref.invalidate(assetListProvider);
      ref.invalidate(filteredAssetsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(categoryDistributionProvider);

      if (mounted) {
        final l10n = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? l10n.assetUpdated : l10n.assetSaved),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? l10n.editAsset : l10n.newAsset),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(l10n.help),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildPhotoUpload(),
                    const SizedBox(height: 24),
                    _buildFormCard(),
                    const SizedBox(height: 16),
                    _buildStatusToggle(),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: _imageFile == null
              ? Border.all(
                  color: AppColors.outlineVariant,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageFile != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _isRemovingBg ? null : _removeBackground,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(180),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isRemovingBg
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_fix_high,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _imageFile = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppL10n.of(context).uploadPhoto,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.24,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFormCard() {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(l10n.assetName),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 18, color: AppColors.onSurface),
            decoration: const InputDecoration(
              hintText: 'e.g. MacBook Pro 14',
              hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 16),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.nameRequired : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel(l10n.category),
          const SizedBox(height: 8),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(l10n.purchasePrice),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          fontSize: 18, color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 16),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, top: 12),
                          child: Text('¥',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurfaceVariant,
                              )),
                        ),
                        prefixIconConstraints: const BoxConstraints(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.priceRequired;
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return l10n.priceInvalid;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(l10n.purchaseDate),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _purchaseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _purchaseDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_purchaseDate),
                          style: const TextStyle(
                              fontSize: 18, color: AppColors.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel(l10n.notes),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 18, color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: l10n.isZh ? '成色、序列号等' : 'Condition, serial number, etc.',
              hintStyle: const TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.24,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final l10n = AppL10n.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (cats) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
              style: const TextStyle(fontSize: 18, color: AppColors.onSurface),
              hint: Text(l10n.selectCategory,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
              items: [
                ...cats.map((cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Row(
                        children: [
                          Icon(CategoryInfo.iconFor(cat.iconName),
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(l10n.isZh ? cat.nameZh : cat.name),
                        ],
                      ),
                    )),
                // "Add custom" option
                const DropdownMenuItem(
                  value: '__custom__',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('+ Custom'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                if (v == '__custom__') {
                  _onAddCategory();
                } else {
                  setState(() => _category = v);
                }
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Text(_category),
      ),
    );
  }

  Future<void> _onAddCategory() async {
    final result = await showAddCategoryDialog(context, ref);
    if (result != null) {
      setState(() => _category = result.name);
    }
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppL10n.of(context).markInService,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              letterSpacing: 0.24,
            ),
          ),
          const Spacer(),
          Switch(
            value: _status == AssetStatus.inService,
            onChanged: (v) {
              setState(() {
                _status = v ? AssetStatus.inService : AssetStatus.retired;
              });
            },
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(204),
        border: const Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _saveAsset,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, size: 22),
          label: Text(
            _isSaving
                ? l10n.saving
                : (_isEditing ? l10n.updateAsset : l10n.saveAsset),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
