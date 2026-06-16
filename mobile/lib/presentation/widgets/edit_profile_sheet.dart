import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';

class EditProfileRequest {
  final String fullName;
  final String phone;
  final String street;
  final String ward;
  final String district;
  final String city;

  const EditProfileRequest({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.ward,
    required this.district,
    required this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'address': {
        'street': street.trim(),
        'ward': ward.trim(),
        'district': district.trim(),
        'city': city.trim(),
      },
    };
  }
}

Future<EditProfileRequest?> showEditProfileSheet(
  BuildContext context, {
  required User user,
  required Color accentColor,
  required String roleLabel,
}) {
  final fullNameCtrl = TextEditingController(text: user.fullName);
  final phoneCtrl = TextEditingController(text: user.phone);
  final streetCtrl = TextEditingController(text: user.address?.street ?? '');
  final wardCtrl = TextEditingController(text: user.address?.ward ?? '');
  final districtCtrl = TextEditingController(text: user.address?.district ?? '');
  final cityCtrl = TextEditingController(text: user.address?.city ?? '');
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<EditProfileRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chỉnh sửa hồ sơ',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cập nhật thông tin cho tài khoản $roleLabel',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: fullNameCtrl,
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ tên';
                        if (value.trim().length < 2) return 'Họ tên quá ngắn';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: phoneCtrl,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Vui lòng nhập số điện thoại';
                        if (!RegExp(r'^0\d{9}4').hasMatch(v)) return 'Số điện thoại không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: streetCtrl,
                      label: 'Số nhà, tên đường',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: wardCtrl,
                            label: 'Phường/Xã',
                            icon: Icons.place_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: districtCtrl,
                            label: 'Quận/Huyện',
                            icon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: cityCtrl,
                      label: 'Tỉnh/Thành phố',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(
                                ctx,
                                EditProfileRequest(
                                  fullName: fullNameCtrl.text,
                                  phone: phoneCtrl.text,
                                  street: streetCtrl.text,
                                  ward: wardCtrl.text,
                                  district: districtCtrl.text,
                                  city: cityCtrl.text,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Lưu thay đổi'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
}) {
  return TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black12),
      ),
    ),
  );
}
