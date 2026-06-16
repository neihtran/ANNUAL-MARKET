import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/market_model.dart';

class ProductFilterSheet extends StatefulWidget {
  final String? selectedCategoryId;
  final List<Category> categories;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final String? sortOrder;
  final Function({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) onApply;

  const ProductFilterSheet({
    super.key,
    this.selectedCategoryId,
    required this.categories,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.sortOrder,
    required this.onApply,
  });

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late String? _selectedCategoryId;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;
  late String? _sortBy;
  late String? _sortOrder;

  final _sortOptions = [
    {'value': 'createdAt', 'label': 'Mới nhất'},
    {'value': 'price_asc', 'label': 'Giá thấp → cao'},
    {'value': 'price_desc', 'label': 'Giá cao → thấp'},
    {'value': 'name', 'label': 'Tên A → Z'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _minPriceCtrl = TextEditingController(
      text: widget.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceCtrl = TextEditingController(
      text: widget.maxPrice?.toStringAsFixed(0) ?? '',
    );

    final sb = widget.sortBy ?? 'createdAt';
    final so = widget.sortOrder ?? 'desc';
    if (sb == 'price' && so == 'asc') {
      _sortBy = 'price_asc';
      _sortOrder = 'asc';
    } else if (sb == 'price' && so == 'desc') {
      _sortBy = 'price_desc';
      _sortOrder = 'desc';
    } else if (sb == 'name') {
      _sortBy = 'name';
      _sortOrder = 'asc';
    } else {
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
    }
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _selectedCategoryId = null;
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
    });
  }

  void _apply() {
    String? actualSortBy;
    String? actualSortOrder;
    if (_sortBy == 'price_asc') {
      actualSortBy = 'price';
      actualSortOrder = 'asc';
    } else if (_sortBy == 'price_desc') {
      actualSortBy = 'price';
      actualSortOrder = 'desc';
    } else {
      actualSortBy = _sortBy;
      actualSortOrder = _sortOrder;
    }

    widget.onApply(
      categoryId: _selectedCategoryId,
      minPrice: double.tryParse(_minPriceCtrl.text),
      maxPrice: double.tryParse(_maxPriceCtrl.text),
      sortBy: actualSortBy,
      sortOrder: actualSortOrder,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(color: Color(0xFFf97316), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category filter
                const Text(
                  'Danh mục',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.categories.length + 1,
                    itemBuilder: (ctx, i) {
                      final isAll = i == 0;
                      final cat = isAll ? null : widget.categories[i - 1];
                      final isSelected = isAll
                          ? _selectedCategoryId == null
                          : _selectedCategoryId == cat!.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategoryId = isAll ? null : cat!.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFf97316) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAll ? 'Tất cả' : cat!.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.white : const Color(0xFF374151),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Price range filter
                const Text(
                  'Khoảng giá (VND)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Từ',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('—', style: TextStyle(color: Colors.grey[400])),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Đến',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sort filter
                const Text(
                  'Sắp xếp theo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sortOptions.map((opt) {
                    final isSelected = _sortBy == opt['value'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _sortBy = opt['value'] as String;
                        _sortOrder = (opt['value'] as String).contains('asc') ? 'asc' : 'desc';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFf97316) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : const Color(0xFF374151),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf97316),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Áp dụng bộ lọc',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
