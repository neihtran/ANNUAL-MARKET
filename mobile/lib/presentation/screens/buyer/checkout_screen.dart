import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/buyer_address.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/address_repository.dart';
import '../../blocs/blocs.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cod';
  final _noteController = TextEditingController();
  bool _isLoading = false;

  // Address management
  List<BuyerAddress> _addresses = [];
  BuyerAddress? _selectedAddress;
  bool _loadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final addresses = await AddressRepository().getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _selectedAddress = addresses.isNotEmpty
              ? (addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first))
              : null;
          _loadingAddresses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double _calcShippingFee(double subtotal) {
    return subtotal >= 200000 ? 0.0 : 15000.0;
  }

  String _normalizeVietnamPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('84') && digits.length == 11) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 9) {
      return '0$digits';
    }
    return digits;
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở link thanh toán'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddAddressDialog() async {
    final addrCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Đà Nẵng');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm địa chỉ mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể', prefixIcon: Icon(Icons.home_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'Quận/Huyện', prefixIcon: Icon(Icons.location_city_outlined))),
              const SizedBox(height: 12),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Thành phố', prefixIcon: Icon(Icons.map_outlined))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buyerPrimary),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result == true && addrCtrl.text.trim().isNotEmpty && mounted) {
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
          // Keep 0,0 if GPS unavailable; textual address is still usable
        }

        final newAddr = BuyerAddress(
          address: addrCtrl.text.trim(),
          district: districtCtrl.text.trim().isEmpty ? null : districtCtrl.text.trim(),
          city: cityCtrl.text.trim(),
          lat: lat,
          lng: lng,
          contactName: context.read<AuthBloc>().state is AuthAuthenticated
              ? (context.read<AuthBloc>().state as AuthAuthenticated).user.fullName
              : '',
          contactPhone: context.read<AuthBloc>().state is AuthAuthenticated
              ? (context.read<AuthBloc>().state as AuthAuthenticated).user.phone
              : '',
          isDefault: _addresses.isEmpty,
        );
        final created = await AddressRepository().createAddress(newAddr);
        if (mounted) {
          setState(() {
            _addresses.add(created);
            _selectedAddress = created;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm địa chỉ thành công'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
    addrCtrl.dispose();
    districtCtrl.dispose();
    cityCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Thanh toán',
          style: TextStyle(
            color: const Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const Center(child: Text('Giỏ hàng trống'));
          }

          final shippingFee = _calcShippingFee(cart.subtotal);
          final total = cart.subtotal + shippingFee;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Địa chỉ giao hàng', isSmallScreen),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildAddressSection(isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _sectionTitle('Phương thức thanh toán', isSmallScreen),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _paymentOption('cod', 'COD (Nhận hàng trả tiền)', Icons.payments_outlined, isSmallScreen: isSmallScreen),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _paymentOption('vnpay', 'Thẻ ATM / VNPay', Icons.account_balance_wallet_outlined, showBadge: true, isSmallScreen: isSmallScreen),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _paymentOption('momo', 'Ví MoMo', Icons.phone_android_outlined, showBadge: true, isSmallScreen: isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _sectionTitle('Ghi chú', isSmallScreen),
                SizedBox(height: isSmallScreen ? 8 : 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 500,
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú cho đơn hàng (tuỳ chọn)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildOrderSummary(cart, shippingFee, total, isSmallScreen),
                SizedBox(height: isSmallScreen ? 80 : 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, bool isSmallScreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 15 : 17,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1a1a1a),
      ),
    );
  }

  Widget _buildAddressSection(bool isSmallScreen) {
    if (_loadingAddresses) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_addresses.isEmpty) {
      return GestureDetector(
        onTap: _showAddAddressDialog,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: Colors.orange.shade700, size: isSmallScreen ? 24 : 28),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm địa chỉ giao hàng',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800, fontSize: isSmallScreen ? 13 : 14),
                    ),
                    Text(
                      'Bạn chưa có địa chỉ nào',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 13, color: Colors.orange.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.orange.shade400, size: isSmallScreen ? 20 : 24),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Column(
            children: [
              ...(_addresses.map((addr) => _buildAddressTile(addr, isSmallScreen))),
              GestureDetector(
                onTap: _showAddAddressDialog,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: isSmallScreen ? 16 : 18, color: Colors.blue.shade600),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Text(
                        'Thêm địa chỉ mới',
                        style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTile(BuyerAddress addr, bool isSmallScreen) {
    final isSelected = _selectedAddress?.id == addr.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddress = addr),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buyerPrimary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: isSelected ? AppColors.buyerPrimary : Colors.grey[200]!, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.buyerPrimary : Colors.grey[400],
              size: isSmallScreen ? 18 : 20,
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        addr.contactName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 14),
                      ),
                      if (addr.isDefault) ...[
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6, vertical: 1),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            'Mặc định',
                            style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    addr.contactPhone,
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 13, color: Colors.grey[600]),
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    addr.address,
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon, {bool showBadge = false, bool isSmallScreen = false}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buyerPrimary.withValues(alpha: 0.06) : Colors.grey[50],
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: isSelected ? AppColors.buyerPrimary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.buyerPrimary : Colors.grey[600], size: isSmallScreen ? 20 : 22),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      color: isSelected ? AppColors.buyerPrimary : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (showBadge)
                    Text(
                      'Thanh toán online an toàn',
                      style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            Container(
              width: isSmallScreen ? 20 : 22,
              height: isSmallScreen ? 20 : 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.buyerPrimary : Colors.grey[400]!, width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: isSmallScreen ? 10 : 12, height: isSmallScreen ? 10 : 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.buyerPrimary)))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartState cart, double shippingFee, double total, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16)),
      child: Column(
        children: [
          _summaryRow('Tạm tính (${cart.itemCount} sản phẩm)', '${_fmt(cart.subtotal)} đ', isSmallScreen),
          SizedBox(height: isSmallScreen ? 6 : 10),
          _summaryRow('Phí vận chuyển', shippingFee > 0 ? '${_fmt(shippingFee)} đ' : 'Miễn phí', isSmallScreen),
          if (cart.subtotal >= 200000)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 4 : 6),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: isSmallScreen ? 12 : 14, color: Colors.green[700]),
                  SizedBox(width: 4),
                  Text(
                    'Đơn từ 200K — Miễn phí vận chuyển!',
                    style: TextStyle(color: Colors.green[700], fontSize: isSmallScreen ? 10 : 12),
                  ),
                ],
              ),
            ),
          if (shippingFee > 0)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 2 : 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: isSmallScreen ? 12 : 14, color: Colors.orange[700]),
                  SizedBox(width: 4),
                  Text(
                    'Phí ship cố định 15,000đ cho mỗi đơn hàng',
                    style: TextStyle(color: Colors.orange[700], fontSize: isSmallScreen ? 10 : 12),
                  ),
                ],
              ),
            ),
          Divider(height: isSmallScreen ? 18 : 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng:',
                style: TextStyle(fontSize: isSmallScreen ? 15 : 17, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_fmt(total)} đ',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.buyerPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 46 : 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _placeOrder(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buyerPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _paymentMethod == 'cod' ? 'Đặt hàng ngay' : 'Tiến hành thanh toán',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (_paymentMethod != 'cod')
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
              child: Text(
                'Bạn sẽ được chuyển đến trang thanh toán VNPay/MoMo',
                style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: isSmallScreen ? 12 : 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 14)),
      ],
    );
  }

  String _fmt(double p) {
    final s = p.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final parts = <String>[];
    var rest = s;
    while (rest.length > 3) {
      parts.insert(0, rest.substring(rest.length - 3));
      rest = rest.substring(0, rest.length - 3);
    }
    parts.insert(0, rest);
    return parts.join(',');
  }

  Future<void> _placeOrder(CartState cart) async {
    if (cart.marketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có thông tin chợ'), backgroundColor: Colors.red));
      return;
    }

    if (_selectedAddress == null && _addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm địa chỉ giao hàng'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final addr = _selectedAddress ?? _addresses.first;
      final shippingFee = _calcShippingFee(cart.subtotal);
      final deliveryAddress = DeliveryAddress(
        address: addr.address,
        lat: addr.lat,
        lng: addr.lng,
        contactName: addr.contactName.isNotEmpty ? addr.contactName : 'Người mua',
        contactPhone: _normalizeVietnamPhone(
          addr.contactPhone.isNotEmpty ? addr.contactPhone : '0900000000',
        ),
      );
      final items = cart.items.map((i) => i.toOrderItem()).toList();

      final order = await OrderRepository().createOrder(
        marketId: cart.marketId!,
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      context.read<CartCubit>().clearCart();

      if (_paymentMethod == 'cod') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đặt hàng thành công! Mã đơn: ${order.orderNumber}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushNamed(context, '/buyer/order', arguments: order.id);
        }
      } else {
        // For VNPay/MoMo: call payment API to get payment URL
        String paymentUrl;
        if (_paymentMethod == 'vnpay') {
          paymentUrl = await _createVNPayPayment(order.id);
        } else {
          paymentUrl = await _createMoMoPayment(order.id);
        }

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Thanh toán online'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payment, size: 60, color: AppColors.buyerPrimary),
                  const SizedBox(height: 16),
                  Text('Mã đơn: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tổng tiền: ${_fmt(order.total)} đ', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Nhấn "Thanh toán" để tiếp tục thanh toán qua ${_paymentMethod == 'vnpay' ? 'VNPay' : 'MoMo'}.')
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushNamed(context, '/buyer/order', arguments: order.id);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _launchPaymentUrl(paymentUrl);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushNamed(context, '/buyer/order', arguments: order.id);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.buyerPrimary),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text('Thanh toán', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _createVNPayPayment(String orderId) async {
    try {
      final response = await OrderRepository().createVNPayPayment(orderId);
      return response['paymentUrl'] ?? '';
    } catch (e) {
      throw Exception('Không thể tạo link VNPay: $e');
    }
  }

  Future<String> _createMoMoPayment(String orderId) async {
    try {
      final response = await OrderRepository().createMoMoPayment(orderId);
      return response['paymentUrl'] ?? '';
    } catch (e) {
      throw Exception('Không thể tạo link MoMo: $e');
    }
  }
}
