import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Cookies from 'js-cookie';
import { apiClient } from '@/lib/api';
import { User } from '@/types';

interface UseAuthReturn {
  user: User | null;
  loading: boolean;
  isAuthenticated: boolean;
  isAdmin: boolean;
  logout: () => void;
}

export function useAuth(): UseAuthReturn {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async () => {
      const token = Cookies.get('accessToken');
      if (!token) {
        setLoading(false);
        router.push('/login');
        return;
      }

      try {
        const fetchedUser = await apiClient.get<User>('/auth/me');
        if (fetchedUser && fetchedUser.role === 'admin') {
          setUser(fetchedUser);
        } else {
          Cookies.remove('accessToken');
          Cookies.remove('refreshToken');
          router.push('/login');
        }
      } catch {
        Cookies.remove('accessToken');
        Cookies.remove('refreshToken');
        router.push('/login');
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, [router]);

  const logout = () => {
    Cookies.remove('accessToken');
    Cookies.remove('refreshToken');
    setUser(null);
    router.push('/login');
  };

  return {
    user,
    loading,
    isAuthenticated: !!user && user.role === 'admin',
    isAdmin: user?.role === 'admin',
    logout,
  };
}
