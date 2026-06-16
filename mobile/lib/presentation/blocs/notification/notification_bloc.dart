import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

// Events
abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationFetchRequested extends NotificationEvent {}

class NotificationMarkAsRead extends NotificationEvent {
  final String notificationId;
  NotificationMarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllAsRead extends NotificationEvent {}

class NotificationDeleted extends NotificationEvent {
  final String notificationId;
  NotificationDeleted(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationReceived extends NotificationEvent {
  final NotificationModel notification;
  NotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

// States
abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationLoaded({required this.notifications, required this.unreadCount});

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(NotificationInitial()) {
    on<NotificationFetchRequested>(_onFetchRequested);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDeleted>(_onDeleted);
    on<NotificationReceived>(_onReceived);
  }

  Future<void> _onFetchRequested(
    NotificationFetchRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    await _repository.markAsRead(event.notificationId);

    final updated = currentState.notifications.map((n) {
      return n.id == event.notificationId ? n.copyWith(isRead: true) : n;
    }).toList();

    emit(NotificationLoaded(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    ));
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    await _repository.markAllAsRead();

    final updated = currentState.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    emit(NotificationLoaded(
      notifications: updated,
      unreadCount: 0,
    ));
  }

  Future<void> _onDeleted(
    NotificationDeleted event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    await _repository.deleteNotification(event.notificationId);

    final updated = currentState.notifications
        .where((n) => n.id != event.notificationId)
        .toList();

    emit(NotificationLoaded(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    ));
  }

  void _onReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final updated = [event.notification, ...currentState.notifications];
      emit(NotificationLoaded(
        notifications: updated,
        unreadCount: currentState.unreadCount + (event.notification.isRead ? 0 : 1),
      ));
    }
  }
}
