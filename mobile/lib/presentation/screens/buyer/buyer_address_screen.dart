import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/buyer_address.dart';
import '../../../data/repositories/address_repository.dart';
import '../../blocs/blocs.dart';

class BuyerAddressScreen extends StatefulWidget {
  const BuyerAddressScreen({super.key});

  @override
  State<BuyerAddressScreen> createState() => _BuyerAddressScreenState();
}

class _BuyerAddressScreenState extends State<BuyerAddressScreen> {
  List<BuyerAddress> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final addresses = await AddressRepository().getAddresses();
      if (mounted) setState(() { _addresses = addresses; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: const Text('Địa chỉ giao hàng', style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.bold, fontSize: 20)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.buyerPrimary),
            onPressed: () => _showAddEditDialog(null),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: AppColors.buyerPrimary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Thêm địa chỉ', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.buyerPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buyerPrimary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Chưa có địa chỉ nào', style: TextStyle(fontSize: 17, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Thêm địa chỉ giao hàng để đặt đơn hàng', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _showAddEditDialog(null),
                icon: const Icon(Icons.add_location),
                label: const Text('Thêm địa chỉ'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.buyerPrimary, side: const BorderSide(color: AppColors.buyerPrimary)),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (ctx, i) => _buildAddressCard(_addresses[i]),
    );
  }

  Widget _buildAddressCard(BuyerAddress addr) {
    return Dismissible(
      key: Key(addr.id ?? addr.address),
      direction: addr.isDefault ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Xóa địa chỉ'),
            content: Text('Bạn có chắc muốn xóa địa chỉ "${addr.address}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        if (addr.id != null) {
          await AddressRepository().deleteAddress(addr.id!);
          _load();
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: addr.isDefault ? AppColors.buyerPrimary : Colors.grey[200]!, width: addr.isDefault ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.buyerPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.buyerPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(addr.contactName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (addr.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Text('Mặc định', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(addr.contactPhone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        onSelected: (value) {
                          if (value == 'edit') _showAddEditDialog(addr);
                          if (value == 'default') _setDefault(addr);
                          if (value == 'delete') _confirmDelete(addr);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Chỉnh sửa')])),
                          if (!addr.isDefault)
                            const PopupMenuItem(value: 'default', child: Row(children: [Icon(Icons.star_outline, size: 20), SizedBox(width: 8), Text('Đặt mặc định')])),
                          if (!addr.isDefault)
                            PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: const TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.home_outlined, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(addr.address, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ),
                    ],
                  ),
                  if (addr.district != null || addr.city != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          [addr.district, addr.city].where((p) => p != null && p.isNotEmpty).join(', '),
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!addr.isDefault)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: GestureDetector(
                  onTap: () => _setDefault(addr),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontSize: 13, color: Colors.orange[700], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefault(BuyerAddress addr) async {
    if (addr.id == null) return;
    try {
      await AddressRepository().setDefaultAddress(addr.id!);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(BuyerAddress addr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa địa chỉ'),
        content: Text('Bạn có chắc muốn xóa địa chỉ "${addr.address}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && addr.id != null) {
      try {
        await AddressRepository().deleteAddress(addr.id!);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddEditDialog(BuyerAddress? existing) async {
    final isEdit = existing != null;
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final districtCtrl = TextEditingController(text: existing?.district ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Đà Nẵng');
    final contactNameCtrl = TextEditingController(text: existing?.contactName ?? '');
    final contactPhoneCtrl = TextEditingController(text: existing?.contactPhone ?? '');
    bool loading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contactNameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên người nhận', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể (số nhà, đường)', prefixIcon: Icon(Icons.home_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtCtrl,
                  decoration: const InputDecoration(labelText: 'Quận/Huyện', prefixIcon: Icon(Icons.location_city_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'Thành phố', prefixIcon: Icon(Icons.map_outlined)),
                ),
                if (loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (addrCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập địa chỉ'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                final authState = context.read<AuthBloc>().state;
                final userName = authState is AuthAuthenticated ? authState.user.fullName : contactNameCtrl.text;
                final userPhone = authState is AuthAuthenticated ? authState.user.phone : contactPhoneCtrl.text;

                setDialogState(() { loading = true; });
                try {
                  // Use existing coordinates, or fetch real GPS
                  double lat = existing?.lat ?? 0;
                  double lng = existing?.lng ?? 0;
                  if (lat == 0 && lng == 0) {
                    try {
                      final pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.medium,
                      );
                      lat = pos.latitude;
                      lng = pos.longitude;
                    } catch (_) {
                      // Keep 0,0 if GPS unavailable; textual address remains valid
                      lat = 0;
                      lng = 0;
                    }
                  }

                  final addr = BuyerAddress(
                    id: existing?.id,
                    address: addrCtrl.text.trim(),
                    district: districtCtrl.text.trim().isEmpty ? null : districtCtrl.text.trim(),
                    city: cityCtrl.text.trim().isEmpty ? 'Đà Nẵng' : cityCtrl.text.trim(),
                    lat: lat,
                    lng: lng,
                    contactName: contactNameCtrl.text.trim().isEmpty ? userName : contactNameCtrl.text.trim(),
                    contactPhone: contactPhoneCtrl.text.trim().isEmpty ? userPhone : contactPhoneCtrl.text.trim(),
                    isDefault: existing?.isDefault ?? false,
                  );

                  if (isEdit && existing?.id != null) {
                    await AddressRepository().updateAddress(existing!.id!, addr);
                  } else {
                    await AddressRepository().createAddress(addr);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setDialogState(() { loading = false; });
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buyerPrimary),
              child: Text(isEdit ? 'Lưu' : 'Thêm'),
            ),
          ],
        ),
      ),
    );

    addrCtrl.dispose();
    districtCtrl.dispose();
    cityCtrl.dispose();
    contactNameCtrl.dispose();
    contactPhoneCtrl.dispose();

    if (result == true) _load();
  }
}
