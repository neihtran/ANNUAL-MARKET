import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/seller_shop_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/product_repository.dart';
import '../../blocs/blocs.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController(text: '1');
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedUnit = 'kg';
  String? _selectedCategoryId;
  List<Category> _categories = [];
  List<String> _productImages = [];
  bool _loadingCategories = false;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _uploadingImages = false;

  final List<String> _units = ['kg', 'bó', 'con', 'cái', 'lít', 'lon', 'gói', 'hộp', 'bịch'];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toString();
      _stockCtrl.text = p.stock.toString();
      _minOrderCtrl.text = p.minOrder.toString();
      _selectedUnit = p.unit;
      _selectedCategoryId = p.categoryId.isNotEmpty ? p.categoryId : null;
      _isAvailable = p.isAvailable;
      _productImages = List<String>.from(p.images);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final client = ApiClient();
      final response = await client.get('/categories');
      final data = response.data;
      final categories = data['success'] == true && data['data']?['categories'] is List
          ? (data['data']['categories'] as List)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Category>[];
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục sản phẩm'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ProductRepository();
      await SellerShopRepository().ensureShopExists(categoryId: _selectedCategoryId!);
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text),
        'stock': int.parse(_stockCtrl.text),
        'minOrder': int.tryParse(_minOrderCtrl.text) ?? 1,
        'unit': _selectedUnit,
        'categoryId': _selectedCategoryId,
        'isAvailable': _isAvailable,
        'images': _productImages,
      };

      if (_isEditing) {
        await repo.updateProduct(widget.product!.id, data);
      } else {
        await repo.createProduct(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Cập nhật sản phẩm thành công' : 'Thêm sản phẩm thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<SellerProductBloc>().add(RefreshSellerProducts());
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadProductImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _uploadingImages = true);
      final imageUrl = await _uploadImage(image);
      if (!mounted) return;
      setState(() {
        _productImages.add(imageUrl);
        _uploadingImages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImages = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload ảnh thất bại: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<String> _uploadImage(XFile file) async {
    final api = ApiClient();
    final imagePart = kIsWeb
        ? MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          )
        : await MultipartFile.fromFile(file.path, filename: file.name);
    final formData = FormData.fromMap({
      'image': imagePart,
    });
    final response = await api.post('/upload/image', data: formData);
    if (response.data['success'] == true) {
      final url = response.data['data']?['url'];
      if (url == null) throw Exception('Upload failed: no URL returned');
      return url.toString().startsWith('http') ? url : '${AppConstants.baseDomain}$url';
    }
    throw Exception(response.data['message'] ?? 'Upload failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: Text(
          _isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
          style: const TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563eb), Color(0xFF1d4ed8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  hintText: 'VD: Rau muống tươi',
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Tên sản phẩm phải có ít nhất 2 ký tự'
                    : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _buildProductImagesSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả chi tiết sản phẩm...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Giá (VNĐ) *',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập giá';
                        final n = double.tryParse(v);
                        if (n == null || n < 0) return 'Giá không hợp lệ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Đơn vị'),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v ?? 'kg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng tồn kho *',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập số lượng';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Số lượng không hợp lệ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đơn hàng tối thiểu',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '1');
                        if (n == null || n < 1) return 'Tối thiểu 1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _loadingCategories
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục sản phẩm *',
                        hintText: 'Chọn danh mục',
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng chọn danh mục' : null,
                    ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: const Text('Đang bán'),
                  subtitle: Text(_isAvailable ? 'Sản phẩm hiển thị với người mua' : 'Sản phẩm bị ẩn'),
                  value: _isAvailable,
                  activeThumbColor: AppColors.sellerPrimary,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _uploadingImages ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sellerPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.sellerPrimary),
            const SizedBox(width: 8),
            const Text(
              'Ảnh sản phẩm',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_productImages.length} ảnh',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_productImages.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _productImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imageUrl = _productImages[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _productImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 34, color: Colors.grey[600]),
                const SizedBox(height: 10),
                const Text(
                  'Thêm ảnh để sản phẩm nổi bật hơn',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buyer sẽ nhìn thấy ảnh này khi xem sản phẩm',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploadingImages ? null : _pickAndUploadProductImage,
            icon: _uploadingImages
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_productImages.isEmpty ? 'Upload ảnh sản phẩm' : 'Thêm ảnh khác'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.sellerPrimary),
              foregroundColor: AppColors.sellerPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minOrderCtrl.dispose();
    super.dispose();
  }
}
