import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

abstract class SellerOrderEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSellerOrders extends SellerOrderEvent {
  final String? status;
  LoadSellerOrders({this.status});
  @override
  List<Object?> get props => [status];
}

abstract class SellerOrderState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SellerOrderInitial extends SellerOrderState {}
class SellerOrderLoading extends SellerOrderState {}

class SellerOrderLoaded extends SellerOrderState {
  final List<Order> orders;
  SellerOrderLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class SellerOrderError extends SellerOrderState {
  final String message;
  SellerOrderError(this.message);
  @override
  List<Object?> get props => [message];
}

class SellerOrderBloc extends Bloc<SellerOrderEvent, SellerOrderState> {
  final OrderRepository _orderRepository;

  SellerOrderBloc({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? OrderRepository(),
        super(SellerOrderInitial()) {
    on<LoadSellerOrders>(_onLoad);
  }

  Future<void> _onLoad(LoadSellerOrders event, Emitter<SellerOrderState> emit) async {
    emit(SellerOrderLoading());
    try {
      final orders = await _orderRepository.getSellerOrders(status: event.status);
      emit(SellerOrderLoaded(orders));
    } catch (e) {
      emit(SellerOrderError(e.toString()));
    }
  }
}
