import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

abstract class SellerProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSellerProducts extends SellerProductEvent {
  final String? categoryId;
  final String? keyword;
  final String? isAvailable;
  LoadSellerProducts({this.categoryId, this.keyword, this.isAvailable});
  @override
  List<Object?> get props => [categoryId, keyword, isAvailable];
}

class AddSellerProduct extends SellerProductEvent {
  final Map<String, dynamic> productData;
  AddSellerProduct(this.productData);
  @override
  List<Object?> get props => [productData];
}

class DeleteSellerProduct extends SellerProductEvent {
  final String productId;
  DeleteSellerProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ToggleSellerProductAvailability extends SellerProductEvent {
  final String productId;
  ToggleSellerProductAvailability(this.productId);
  @override
  List<Object?> get props => [productId];
}

class RefreshSellerProducts extends SellerProductEvent {}

abstract class SellerProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SellerProductInitial extends SellerProductState {}
class SellerProductLoading extends SellerProductState {}

class SellerProductLoaded extends SellerProductState {
  final List<Product> products;
  SellerProductLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class SellerProductError extends SellerProductState {
  final String message;
  SellerProductError(this.message);
  @override
  List<Object?> get props => [message];
}

class SellerProductActionSuccess extends SellerProductState {
  final String message;
  SellerProductActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SellerProductBloc extends Bloc<SellerProductEvent, SellerProductState> {
  final ProductRepository _productRepository;

  SellerProductBloc({ProductRepository? productRepository})
      : _productRepository = productRepository ?? ProductRepository(),
        super(SellerProductInitial()) {
    on<LoadSellerProducts>(_onLoad);
    on<RefreshSellerProducts>(_onRefresh);
    on<AddSellerProduct>(_onAdd);
    on<DeleteSellerProduct>(_onDelete);
    on<ToggleSellerProductAvailability>(_onToggle);
  }

  Future<void> _onLoad(LoadSellerProducts event, Emitter<SellerProductState> emit) async {
    emit(SellerProductLoading());
    try {
      final products = await _productRepository.getSellerProducts(
        categoryId: event.categoryId,
        keyword: event.keyword,
        isAvailable: event.isAvailable,
      );
      emit(SellerProductLoaded(products));
    } catch (e) {
      emit(SellerProductError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshSellerProducts event, Emitter<SellerProductState> emit) async {
    try {
      final products = await _productRepository.getSellerProducts();
      emit(SellerProductLoaded(products));
    } catch (e) {
      emit(SellerProductError(e.toString()));
    }
  }

  Future<void> _onAdd(AddSellerProduct event, Emitter<SellerProductState> emit) async {
    emit(SellerProductLoading());
    try {
      await _productRepository.createProduct(event.productData);
      final products = await _productRepository.getSellerProducts();
      emit(SellerProductLoaded(products));
    } catch (e) {
      emit(SellerProductError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteSellerProduct event, Emitter<SellerProductState> emit) async {
    emit(SellerProductLoading());
    try {
      await _productRepository.deleteProduct(event.productId);
      final products = await _productRepository.getSellerProducts();
      emit(SellerProductLoaded(products));
    } catch (e) {
      emit(SellerProductError(e.toString()));
    }
  }

  Future<void> _onToggle(ToggleSellerProductAvailability event, Emitter<SellerProductState> emit) async {
    emit(SellerProductLoading());
    try {
      await _productRepository.toggleAvailability(event.productId);
      final products = await _productRepository.getSellerProducts();
      emit(SellerProductLoaded(products));
    } catch (e) {
      emit(SellerProductError(e.toString()));
    }
  }
}
