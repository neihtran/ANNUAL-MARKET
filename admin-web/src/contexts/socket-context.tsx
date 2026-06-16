/**
 * Socket.IO context for real-time notifications in the admin web.
 * Provides a singleton socket connection that auto-connects on auth
 * and dispatches events to notification listeners.
 */
'use client';

import * as React from 'react';
import { io, Socket } from 'socket.io-client';
import Cookies from 'js-cookie';

const SOCKET_URL =
  typeof window !== 'undefined'
    ? process.env.NEXT_PUBLIC_API_URL?.replace('/api/v1', '') || 'http://localhost:3001'
    : '';

export interface SocketNotification {
  _id?: string;
  title: string;
  body: string;
  type: string;
  referenceId?: string;
  data?: Record<string, unknown>;
  isRead?: boolean;
  createdAt?: string;
  [key: string]: unknown;
}

type NotificationHandler = (notification: SocketNotification) => void;

interface SocketContextValue {
  socket: Socket | null;
  isConnected: boolean;
  onNotification: (handler: NotificationHandler) => () => void;
}

const SocketContext = React.createContext<SocketContextValue>({
  socket: null,
  isConnected: false,
  onNotification: () => () => {},
});

export function SocketProvider({ children }: { children: React.ReactNode }) {
  const [socket, setSocket] = React.useState<Socket | null>(null);
  const [isConnected, setIsConnected] = React.useState(false);
  const handlersRef = React.useRef<NotificationHandler[]>([]);

  // Connect socket when admin is authenticated
  React.useEffect(() => {
    const token = Cookies.get('accessToken');
    // Use the actual admin userId from userData cookie so notifications
    // for this specific admin can be delivered to the right socket room.
    const userDataStr = Cookies.get('userData');
    let adminUserId: string | undefined;
    if (userDataStr) {
      try {
        const parsed = JSON.parse(userDataStr);
        adminUserId = parsed._id || parsed.id;
      } catch (_) { /* ignore parse errors */ }
    }
    // Fallback: join as 'admin' string only if no userData cookie
    if (!token || !SOCKET_URL) return;

    const joinId = adminUserId || 'admin';
    const newSocket = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
    });

    newSocket.on('connect', () => {
      console.log('[Socket] Connected:', newSocket.id);
      setIsConnected(true);

      // Identify as admin so backend can send user-specific notifications
      // Use the real userId so Socket.IO delivers to room `user:{adminId}`
      newSocket.emit('user:join', joinId);
    });

    newSocket.on('disconnect', () => {
      console.log('[Socket] Disconnected');
      setIsConnected(false);
    });

    newSocket.on('connect_error', (err) => {
      console.warn('[Socket] Connection error:', err.message);
      setIsConnected(false);
    });

    // Listen for real-time notifications from backend
    newSocket.on('notification:new', (notification: SocketNotification) => {
      console.log('[Socket] New notification received:', notification);
      handlersRef.current.forEach((handler) => {
        try {
          handler(notification);
        } catch (e) {
          console.error('[Socket] Handler error:', e);
        }
      });
    });

    // Also listen for user_register events (for new registration alerts)
    newSocket.on('admin:new_registration', (data: SocketNotification) => {
      console.log('[Socket] New registration:', data);
      const notification: SocketNotification = {
        title: data.title || 'Đăng ký mới',
        body: data.body || 'Có người dùng mới đăng ký tài khoản',
        type: 'user_register',
        referenceId: data.referenceId,
        data: data.data,
        createdAt: new Date().toISOString(),
      };
      handlersRef.current.forEach((handler) => {
        try {
          handler(notification);
        } catch (e) {
          console.error('[Socket] Handler error:', e);
        }
      });
    });

    setSocket(newSocket);

    return () => {
      newSocket.disconnect();
      setSocket(null);
      setIsConnected(false);
    };
  }, []);

  const onNotification = React.useCallback((handler: NotificationHandler) => {
    handlersRef.current.push(handler);
    return () => {
      handlersRef.current = handlersRef.current.filter((h) => h !== handler);
    };
  }, []);

  return (
    <SocketContext.Provider value={{ socket, isConnected, onNotification }}>
      {children}
    </SocketContext.Provider>
  );
}

export function useSocket() {
  return React.useContext(SocketContext);
}
