import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/socket_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String role;
  final List<String>? categoryIds;
  final String? marketId;
  /// For sellers: [{ type: 'cccd', url: '...' }]
  final List<Map<String, String>>? documents;

  AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.role = 'buyer',
    this.categoryIds,
    this.marketId,
    this.documents,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone, role, categoryIds, marketId, documents];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final User user;
  AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthPendingApproval extends AuthState {
  final User user;

  AuthPendingApproval(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthRejected extends AuthState {
  final String reason;

  AuthRejected(this.reason);

  @override
  List<Object?> get props => [reason];
}

class AuthBanned extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Emit loading first so UI shows a loading indicator
    emit(AuthLoading());

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        try {
          final user = await _authRepository.getCurrentUser();
          if (user != null) {
            if (user.isRejected) {
              emit(AuthRejected('Tài khoản đã bị từ chối. Vui lòng liên hệ admin.'));
              return;
            }
            if (user.status == 'banned') {
              emit(AuthBanned());
              return;
            }
            if (!user.isApproved && user.role != 'buyer' && user.role != 'admin') {
              emit(AuthPendingApproval(user));
              return;
            }
            emit(AuthAuthenticated(user));
            return;
          }
        } catch (_) {
          // getCurrentUser failed — token may be expired, clear session
          await _authRepository.logout();
        }
      }
      emit(AuthUnauthenticated());
    } catch (e) {
      // Network unreachable, server down, or any unexpected error
      // Always emit unauthenticated so the app is never stuck on the splash screen
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(event.email, event.password);
      final user = result['user'] as User;

      if (user.isRejected) {
        emit(AuthRejected('Tài khoản đã bị từ chối. Vui lòng liên hệ admin.'));
        return;
      }

      if (user.status == 'banned') {
        emit(AuthBanned());
        return;
      }

      if (!user.isApproved && user.role != 'buyer' && user.role != 'admin') {
        emit(AuthPendingApproval(user));
        return;
      }

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phone: event.phone,
        role: event.role,
        categoryIds: event.categoryIds,
        marketId: event.marketId,
        documents: event.documents,
      );
      final user = result['user'] as User;

      if (!user.isApproved && user.role != 'buyer' && user.role != 'admin') {
        emit(AuthPendingApproval(user));
        return;
      }

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Await logout so storage is cleared BEFORE emitting unauthenticated.
    // This prevents a race where the next login reads stale tokens.
    try {
      SocketService().disconnect();
      await _authRepository.logout();
    } catch (_) {
      // Storage clearing is the primary concern; API errors are secondary
    }

    // Always emit unauthenticated after storage is confirmed cleared
    emit(AuthUnauthenticated());
  }

  Future<void> _onUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.user));
  }
}
