import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/blocs.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/user_model.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    String? isAvailable;
    if (_selectedFilter == 'available') {
      isAvailable = 'true';
    } else if (_selectedFilter == 'unavailable') {
      isAvailable = 'false';
    }
    context.read<SellerProductBloc>().add(
      LoadSellerProducts(keyword: _searchController.text, isAvailable: isAvailable),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Sản phẩm của tôi',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm sản phẩm...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadProducts();
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _loadProducts(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sellerPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PopupMenuButton<String>(
                      color: Colors.white,
                      onSelected: (v) {
                        setState(() => _selectedFilter = v == 'all' ? null : v);
                        _loadProducts();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'all', child: Text('Tất cả')),
                        const PopupMenuItem(value: 'available', child: Text('Đang bán')),
                        const PopupMenuItem(value: 'unavailable', child: Text('Tạm ngưng')),
                      ],
                      child: Center(
                        child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<SellerProductBloc, SellerProductState>(
              listener: (context, state) {
                if (state is SellerProductError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                  );
                }
              },
              builder: (context, state) {
                if (state is SellerProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SellerProductLoaded) {
                  if (state.products.isEmpty) {
                    return _emptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _loadProducts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        return _ProductListTile(
                          product: product,
                          onToggle: () => _toggleAvailability(product),
                          onEdit: () => _editProduct(product),
                          onDelete: () => _confirmDelete(product),
                        );
                      },
                    ),
                  );
                }
                return _emptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          final isNotApproved = user != null && user.role == 'seller' && !user.isApproved;
          return FloatingActionButton(
            backgroundColor: AppColors.sellerPrimary,
            onPressed: () async {
              if (isNotApproved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tài khoản chưa được duyệt. Vui lòng chờ admin phê duyệt.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final result = await Navigator.pushNamed(context, '/seller/add-product');
              if (result == true) _loadProducts();
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isNotApproved = user != null && user.role == 'seller' && !user.isApproved;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          if (isNotApproved) ...[
            const Text(
              'Tài khoản chưa được duyệt',
              style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chờ admin duyệt trước khi thêm sản phẩm',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text('Chưa có sản phẩm nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/seller/add-product');
                if (result == true) _loadProducts();
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(Product product) async {
    final repo = ProductRepository();
    try {
      await repo.toggleAvailability(product.id);
      if (mounted) _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _editProduct(Product product) {
    Navigator.pushNamed(context, '/seller/add-product', arguments: product);
  }

  Future<void> _confirmDelete(Product product) async {
    final repo = ProductRepository();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await repo.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa sản phẩm'), backgroundColor: AppColors.success),
          );
          _loadProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.images.isNotEmpty
              ? Image.network(
                  product.images.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: product.isAvailable ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatPrice(product.price)} / ${product.unit}',
              style: const TextStyle(color: AppColors.sellerPrimary, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Tồn: ${product.stock}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'toggle':
                onToggle();
                break;
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    product.isAvailable ? Icons.pause_circle : Icons.play_circle,
                    color: AppColors.sellerPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(product.isAvailable ? 'Tạm ngưng' : 'Bán lại'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}
