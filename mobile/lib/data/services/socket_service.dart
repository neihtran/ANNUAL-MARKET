import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/app_constants.dart';

typedef SocketCallback = void Function(dynamic data);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  
  final Map<String, List<SocketCallback>> _listeners = {};
  final Map<String, StreamController> _streamControllers = {};

  bool get isConnected => _socket?.connected ?? false;

  void connect(String userId) {
    final serverUrl = AppConstants.baseUrl.replaceAll('/api/v1', '').replaceAll('/api', '');
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(3)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      developer.log('Socket connected to $serverUrl', name: 'SocketService');
      _socket!.emit('user:join', userId);
      _socket!.emit('shipper:available_join');
    });

    _socket!.onDisconnect((_) {
      developer.log('Socket disconnected', name: 'SocketService');
    });

    _socket!.onError((error) {
      developer.log('Socket error: $error', name: 'SocketService');
    });

    _socket!.onConnectError((error) {
      developer.log('Socket connection error: $error — Is the server running at $serverUrl?', name: 'SocketService');
    });

    _socket!.on('order:new_available', (data) {
      _notifyListeners('order:new_available', data);
    });

    _socket!.on('order:taken', (data) {
      _notifyListeners('order:taken', data);
    });

    _socket!.on('order:status_changed', (data) {
      _notifyListeners('order:status_changed', data);
    });

    _socket!.on('shipper:location', (data) {
      _notifyListeners('shipper:location', data);
    });

    _socket!.on('notification:new', (data) {
      _notifyListeners('notification:new', data);
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    for (var controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _listeners.clear();
  }

  void joinOrderRoom(String orderId) {
    _socket?.emit('order:join', orderId);
  }

  void leaveOrderRoom(String orderId) {
    _socket?.emit('order:leave', orderId);
  }

  void updateShipperLocation(String orderId, double lat, double lng) {
    _socket?.emit('shipper:update_location', {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
    });
  }

  void addListener(String event, SocketCallback callback) {
    _listeners.putIfAbsent(event, () => []);
    _listeners[event]!.add(callback);
  }

  void removeListener(String event, SocketCallback callback) {
    _listeners[event]?.remove(callback);
  }

  void _notifyListeners(String event, dynamic data) {
    final callbacks = _listeners[event];
    if (callbacks != null) {
      for (var callback in callbacks) {
        callback(data);
      }
    }
    
    final controller = _streamControllers[event];
    controller?.add(data);
  }

  Stream<T> listen<T>(String event) {
    _streamControllers.putIfAbsent(event, () => StreamController.broadcast());
    return _streamControllers[event]!.stream.cast<T>();
  }
}
