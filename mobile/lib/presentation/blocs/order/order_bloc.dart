import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

// Events
abstract class OrderEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {}

class LoadOrderDetail extends OrderEvent {
  final String orderId;
  LoadOrderDetail(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class CreateOrder extends OrderEvent {
  final String marketId;
  final List<Map<String, dynamic>> items;
  final DeliveryAddress deliveryAddress;
  final String paymentMethod;
  final String? note;

  CreateOrder({
    required this.marketId,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.note,
  });

  @override
  List<Object?> get props => [marketId, items, deliveryAddress, paymentMethod, note];
}

class CancelOrder extends OrderEvent {
  final String orderId;
  final String reason;

  CancelOrder({required this.orderId, required this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

// States
abstract class OrderState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  OrderLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final Order order;
  OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderCreated extends OrderState {
  final Order order;
  OrderCreated(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderCancelled extends OrderState {}

class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;

  OrderBloc({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? OrderRepository(),
        super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<LoadOrderDetail>(_onLoadOrderDetail);
    on<CreateOrder>(_onCreateOrder);
    on<CancelOrder>(_onCancelOrder);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    try {
      final orders = await _orderRepository.getOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onLoadOrderDetail(
    LoadOrderDetail event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    try {
      final order = await _orderRepository.getOrderById(event.orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    try {
      final order = await _orderRepository.createOrder(
        marketId: event.marketId,
        items: event.items,
        deliveryAddress: event.deliveryAddress,
        paymentMethod: event.paymentMethod,
        note: event.note,
      );
      emit(OrderCreated(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    try {
      await _orderRepository.cancelOrder(event.orderId, event.reason);
      emit(OrderCancelled());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
