import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/market_model.dart';
import '../../../data/models/buyer_address.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Address fields
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedRole = 'buyer';
  String? _selectedMarketId;
  List<Market> _markets = [];
  List<Category> _categories = [];
  Set<String> _selectedCategoryIds = {};
  bool _loadingCategories = false;
  bool _loadingMarkets = false;
  bool _registering = false;
  bool _registrationComplete = false;

  // CCCD upload for sellers
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _uploadedCccdUrls = [];
  bool _uploadingCccd = false;
  // Driver license upload for shippers
  List<String> _uploadedDriverLicenseUrls = [];
  bool _uploadingDriverLicense = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadMarkets();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final client = ApiClient();
      final response = await client.get('/categories');
      final data = response.data;
      if (data['success'] == true && data['data']['categories'] != null) {
        setState(() {
          _categories = (data['data']['categories'] as List)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadMarkets() async {
    setState(() => _loadingMarkets = true);
    try {
      final client = ApiClient();
      final response = await client.get('/markets');
      final data = response.data;
      if (data['success'] == true && data['data']['markets'] != null) {
        setState(() {
          _markets = (data['data']['markets'] as List)
              .map((e) => Market.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMarkets = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'seller') {
      if (_selectedMarketId == null) {
        _showSnackBar('Vui lòng chọn chợ', Colors.orange);
        return;
      }
      if (_selectedCategoryIds.isEmpty) {
        _showSnackBar('Vui lòng chọn ít nhất 1 danh mục', Colors.orange);
        return;
      }
      if (_uploadedCccdUrls.isEmpty) {
        _showSnackBar('Vui lòng upload ảnh CCCD/CMND', Colors.orange);
        return;
      }
    }

    // Validate address for buyer
    if (_selectedRole == 'buyer') {
      if (_addressController.text.trim().isEmpty) {
        _showSnackBar('Vui lòng nhập địa chỉ giao hàng', Colors.orange);
        return;
      }
    }

    // Validate driver license for shipper
    if (_selectedRole == 'shipper') {
      if (_uploadedDriverLicenseUrls.isEmpty) {
        _showSnackBar('Vui lòng upload ảnh bằng lái xe', Colors.orange);
        return;
      }
    }

    setState(() => _registering = true);

    try {
      // Build documents for sellers / shippers
      final List<Map<String, String>>? docs = _selectedRole == 'seller' && _uploadedCccdUrls.isNotEmpty
          ? _uploadedCccdUrls.map((url) => {'type': 'cccd', 'url': url}).toList()
          : (_selectedRole == 'shipper' && _uploadedDriverLicenseUrls.isNotEmpty
              ? _uploadedDriverLicenseUrls.map((url) => {'type': 'driver_license', 'url': url}).toList()
              : null);

      // Register first
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          marketId: _selectedRole == 'seller' ? _selectedMarketId : null,
          categoryIds: _selectedRole == 'seller' && _selectedCategoryIds.isNotEmpty
              ? _selectedCategoryIds.toList()
              : null,
          documents: docs,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _createBuyerAddressAndNavigate() async {
    try {
      double lat = 0;
      double lng = 0;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        // Keep 0,0 if GPS unavailable; backend/mobile can still store textual address
      }

      final address = BuyerAddress(
        address: _addressController.text.trim(),
        district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        city: _cityController.text.trim().isEmpty ? 'Đà Nẵng' : _cityController.text.trim(),
        lat: lat,
        lng: lng,
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        isDefault: true,
      );
      await AddressRepository().createAddress(address);
    } catch (_) {
      // Address creation failed silently - registration still succeeded
    }
    if (mounted) _navigateHome('buyer');
  }

  void _navigateHome(String role) {
    String homeRoute;
    switch (role) {
      case 'seller': homeRoute = '/seller'; break;
      case 'shipper': homeRoute = '/shipper'; break;
      default: homeRoute = '/buyer';
    }
    Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showSnackBar(state.message, Colors.red);
          } else if (state is AuthAuthenticated) {
            if (_selectedRole == 'buyer' && !_registrationComplete) {
              _registrationComplete = true;
              _createBuyerAddressAndNavigate();
            } else {
              _navigateHome(state.user.role);
            }
          } else if (state is AuthPendingApproval) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            _showSnackBar('Đăng ký thành công! Tài khoản đang chờ quản trị duyệt.', Colors.blue);
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRoleSelector(),
                        if (_selectedRole == 'seller') ...[
                          const SizedBox(height: 24),
                          _buildSellerFields(),
                        ],
                        if (_selectedRole == 'buyer') ...[
                          const SizedBox(height: 24),
                          _buildBuyerAddressSection(),
                        ],
                        if (_selectedRole == 'shipper') ...[
                          const SizedBox(height: 24),
                          _buildShipperFields(),
                        ],
                        const SizedBox(height: 24),
                        _buildAccountFields(),
                        const SizedBox(height: 28),
                        _buildRegisterButton(),
                        const SizedBox(height: 16),
                        _buildLoginLink(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16a34a), Color(0xFF22c55e)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const Text('Tạo tài khoản mới', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'Đăng ký để bắt đầu mua sắm',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bạn là:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _RoleCard(icon: Icons.shopping_cart_outlined, label: 'Người mua', isSelected: _selectedRole == 'buyer', color: const Color(0xFFf97316), onTap: () => setState(() => _selectedRole = 'buyer'))),
            const SizedBox(width: 10),
            Expanded(child: _RoleCard(icon: Icons.store_outlined, label: 'Người bán', isSelected: _selectedRole == 'seller', color: const Color(0xFF2563eb), onTap: () => setState(() => _selectedRole = 'seller'))),
            const SizedBox(width: 10),
            Expanded(child: _RoleCard(icon: Icons.delivery_dining, label: 'Shipper', isSelected: _selectedRole == 'shipper', color: const Color(0xFF0d9488), onTap: () => setState(() => _selectedRole = 'shipper'))),
          ],
        ),
      ],
    );
  }

  Widget _buildSellerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn chợ bán hàng:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _loadingMarkets
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _markets.isEmpty
                ? Text('Không có chợ nào', style: TextStyle(color: Colors.grey[600]))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMarketId,
                        isExpanded: true,
                        hint: const Text('Chọn chợ'),
                        items: _markets.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedMarketId = v),
                      ),
                    ),
                  ),
        const SizedBox(height: 24),
        const Text('Danh mục bán hàng (chọn ít nhất 1):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _loadingCategories
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _categories.isEmpty
                ? Text('Không có danh mục nào', style: TextStyle(color: Colors.grey[600]))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategoryIds.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.name),
                        selected: selected,
                        onSelected: (s) => setState(() => s ? _selectedCategoryIds.add(cat.id) : _selectedCategoryIds.remove(cat.id)),
                        selectedColor: const Color(0xFF2563eb).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF2563eb),
                        labelStyle: TextStyle(color: selected ? const Color(0xFF2563eb) : Colors.grey[700], fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: selected ? const Color(0xFF2563eb) : Colors.grey[300]!)),
                      );
                    }).toList(),
                  ),
        if (_selectedCategoryIds.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('Vui lòng chọn ít nhất 1 danh mục', style: TextStyle(color: Colors.red[700], fontSize: 12))),
        const SizedBox(height: 24),
        const Text('Upload CCCD/CMND (bắt buộc):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Chụp ảnh mặt trước CCCD để xác minh danh tính', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        _buildCccdUploadSection(),
      ],
    );
  }

  Widget _buildCccdUploadSection() {
    return Column(
      children: [
        // Uploaded images preview
        if (_uploadedCccdUrls.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedCccdUrls.length,
              itemBuilder: (ctx, i) => Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        _uploadedCccdUrls[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _uploadedCccdUrls.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    if (i == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Mặt trước', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Upload button
        if (_uploadedCccdUrls.isEmpty)
          GestureDetector(
            onTap: _uploadingCccd ? null : _pickAndUploadCccd,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200!, style: BorderStyle.solid),
              ),
              child: _uploadingCccd
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 32, color: Colors.blue.shade600),
                        const SizedBox(height: 8),
                        Text('Chạm để chụp ảnh CCCD', style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                        const SizedBox(height: 4),
                        Text('(hoặc chọn từ thư viện)', style: TextStyle(fontSize: 11, color: Colors.blue.shade400)),
                      ],
                    ),
            ),
          )
        else
          TextButton.icon(
            onPressed: _uploadingCccd ? null : _pickAndUploadCccd,
            icon: Icon(Icons.add_photo_alternate_outlined, color: Colors.blue.shade600),
            label: Text('Thêm ảnh CCCD mặt sau', style: TextStyle(color: Colors.blue.shade600)),
          ),
        if (_uploadedCccdUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Vui lòng upload ít nhất 1 ảnh CCCD', style: TextStyle(color: Colors.red[700], fontSize: 12)),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadCccd() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (image == null) return;

      setState(() => _uploadingCccd = true);
      final url = await _uploadImage(image);
      if (mounted) setState(() { _uploadedCccdUrls.add(url); _uploadingCccd = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingCccd = false);
        _showSnackBar('Upload ảnh thất bại: $e', Colors.red);
      }
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
      // Convert relative URL to absolute if needed
      return url.toString().startsWith('http') ? url : '${AppConstants.baseDomain}$url';
    }
    throw Exception(response.data['message'] ?? 'Upload failed');
  }

  Widget _buildShipperFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF0d9488)),
            const SizedBox(width: 6),
            const Text('Xác minh tài xế', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('Bắt buộc', style: TextStyle(fontSize: 11, color: Color(0xFF0d9488), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Upload ảnh bằng lái xe để quản trị viên xác minh và phê duyệt tài khoản shipper của bạn.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 16),
        _buildDriverLicenseUploadSection(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Bằng lái xe phải còn hạn. Tài khoản shipper sẽ chờ quản trị viên phê duyệt sau khi đăng ký.', style: TextStyle(fontSize: 12, color: Colors.teal.shade700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverLicenseUploadSection() {
    return Column(
      children: [
        // Uploaded images preview
        if (_uploadedDriverLicenseUrls.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedDriverLicenseUrls.length,
              itemBuilder: (ctx, i) => Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        _uploadedDriverLicenseUrls[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _uploadedDriverLicenseUrls.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF0d9488), borderRadius: BorderRadius.circular(4)),
                        child: const Text('BLX', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Upload button
        if (_uploadedDriverLicenseUrls.isEmpty)
          GestureDetector(
            onTap: _uploadingDriverLicense ? null : _pickAndUploadDriverLicense,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200!),
              ),
              child: _uploadingDriverLicense
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 32, color: Colors.teal.shade600),
                        const SizedBox(height: 8),
                        Text('Chạm để chụp ảnh bằng lái xe', style: TextStyle(fontSize: 13, color: Colors.teal.shade700)),
                        const SizedBox(height: 4),
                        Text('(hoặc chọn từ thư viện)', style: TextStyle(fontSize: 11, color: Colors.teal.shade400)),
                      ],
                    ),
            ),
          )
        else
          TextButton.icon(
            onPressed: _uploadingDriverLicense ? null : _pickAndUploadDriverLicense,
            icon: Icon(Icons.add_photo_alternate_outlined, color: Colors.teal.shade600),
            label: Text('Thêm ảnh bằng lái xe', style: TextStyle(color: Colors.teal.shade600)),
          ),
        if (_uploadedDriverLicenseUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Vui lòng upload ít nhất 1 ảnh bằng lái xe', style: TextStyle(color: Colors.red[700], fontSize: 12)),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadDriverLicense() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (image == null) return;

      setState(() => _uploadingDriverLicense = true);
      final url = await _uploadImage(image);
      if (mounted) setState(() { _uploadedDriverLicenseUrls.add(url); _uploadingDriverLicense = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingDriverLicense = false);
        _showSnackBar('Upload ảnh thất bại: $e', Colors.red);
      }
    }
  }
  Widget _buildBuyerAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFf97316)),
            const SizedBox(width: 6),
            const Text('Địa chỉ giao hàng mặc định', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('Bắt buộc', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Địa chỉ này sẽ được dùng làm địa chỉ giao hàng mặc định cho đơn hàng của bạn.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        _buildTextField(_addressController, 'Địa chỉ cụ thể (số nhà, đường, phường/xã)', Icons.home_outlined, TextInputType.streetAddress, (v) => v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_districtController, 'Quận/Huyện', Icons.location_city_outlined, TextInputType.text, null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(_cityController, 'Thành phố', Icons.map_outlined, TextInputType.text, null, initialValue: 'Đà Nẵng'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Bạn có thể thêm hoặc chỉnh sửa địa chỉ giao hàng sau trong phần Hồ sơ.', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    TextInputType keyboardType,
    String? Function(String?)? validator, {
    String? initialValue,
  }) {
    if (initialValue != null && ctrl.text.isEmpty) ctrl.text = initialValue;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
      ),
      validator: validator,
    );
  }

  Widget _buildAccountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông tin tài khoản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildTextField(_nameController, 'Họ và tên', Icons.person_outlined, TextInputType.name, (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null),
        const SizedBox(height: 12),
        _buildTextField(_emailController, 'Email', Icons.email_outlined, TextInputType.emailAddress, (v) {
          if (v == null || v.isEmpty) return 'Vui lòng nhập email';
          if (!v.contains('@')) return 'Email không hợp lệ';
          return null;
        }),
        const SizedBox(height: 12),
        _buildTextField(_phoneController, 'Số điện thoại', Icons.phone_outlined, TextInputType.phone, (v) {
          if (v == null || v.isEmpty) return 'Vui lòng nhập số điện thoại';
          if (v.length < 10) return 'Số điện thoại không hợp lệ';
          return null;
        }),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Ít nhất 6 ký tự',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
            if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock_outlined),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
          ),
          validator: (v) {
            if (v != _passwordController.text) return 'Mật khẩu không khớp';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading || _registering;
        return SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16a34a),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Đã có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đăng nhập', style: TextStyle(color: Color(0xFF16a34a), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey[200]!, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
