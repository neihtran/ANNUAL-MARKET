import axios, { AxiosInstance, AxiosError, InternalAxiosRequestConfig } from 'axios';
import Cookies from 'js-cookie';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api/v1';

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface PaginatedResult<T> {
  data: T;
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface ApiError {
  success: false;
  message: string;
  error: {
    code: string;
    details?: Array<{ field: string; message: string }>;
  };
}

export function isApiError(error: unknown): error is ApiError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'success' in error &&
    (error as ApiError).success === false
  );
}

export function getErrorMessage(error: unknown): string {
  if (isApiError(error)) {
    return error.message;
  }
  if (axios.isAxiosError(error)) {
    return error.response?.data?.message || error.message;
  }
  return 'Đã xảy ra lỗi không mong muốn';
}

class ApiClient {
  private client: AxiosInstance;
  // Queue + flag to prevent concurrent token refresh race condition
  private refreshPromise: Promise<string | null> | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000,
      withCredentials: true,
    });

    this.client.interceptors.request.use(
      (config: InternalAxiosRequestConfig) => {
        const token = Cookies.get('accessToken');
        if (token && config.headers) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;

          try {
            // Deduplicate concurrent refresh attempts using a shared promise.
            // Only the first request triggers refresh; others wait for the same promise.
            if (!this.refreshPromise) {
              this.refreshPromise = this._doRefresh();
            }
            const newAccessToken = await this.refreshPromise;

            if (newAccessToken) {
              if (originalRequest.headers) {
                originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
              }
              return this.client(originalRequest);
            }
          } catch (refreshError) {
            Cookies.remove('accessToken');
            Cookies.remove('refreshToken');
            Cookies.remove('userData');
            if (typeof window !== 'undefined') {
              window.location.href = '/login';
            }
            return Promise.reject(refreshError);
          } finally {
            this.refreshPromise = null;
          }
        }

        return Promise.reject(error);
      }
    );
  }

  private async _doRefresh(): Promise<string | null> {
    try {
      const refreshToken = Cookies.get('refreshToken');
      if (!refreshToken) return null;

      // Use the shared axios instance (withCredentials:true) so cookies are sent
      const response = await this.client.post('/auth/refresh', {
        refreshToken,
      });

      const { accessToken, refreshToken: newRefreshToken } = response.data.data;
      Cookies.set('accessToken', accessToken, { expires: 7 });
      Cookies.set('refreshToken', newRefreshToken, { expires: 30 });
      return accessToken;
    } catch {
      return null;
    }
  }

  async get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
    try {
      const response = await this.client.get<ApiResponse<T>>(url, { params });
      return response.data.data;
    } catch (error: unknown) {
      const err = error as AxiosError<{ message?: string; error?: { code?: string } }>;
      // Surface structured API errors with messages so the UI can show them
      if (err.response?.data?.message) {
        const msg = err.response.data.message;
        const apiError: ApiError = {
          success: false,
          message: msg,
          error: {
            code: err.response.data?.error?.code || 'SERVER_ERROR',
          },
        };
        throw apiError;
      }
      throw error;
    }
  }

  async getWithPagination<T>(url: string, params?: Record<string, unknown>): Promise<PaginatedResult<T>> {
    try {
      const response = await this.client.get<ApiResponse<T>>(url, { params });
      return {
        data: response.data.data,
        pagination: response.data.pagination,
      };
    } catch (error: unknown) {
      const err = error as AxiosError<{ message?: string; error?: { code?: string } }>;
      if (err.response?.data?.message) {
        const msg = err.response.data.message;
        const apiError: ApiError = {
          success: false,
          message: msg,
          error: {
            code: err.response.data?.error?.code || 'SERVER_ERROR',
          },
        };
        throw apiError;
      }
      throw error;
    }
  }

  async post<T>(url: string, data?: unknown): Promise<T> {
    const response = await this.client.post<ApiResponse<T>>(url, data);
    return response.data.data;
  }

  async put<T>(url: string, data?: unknown): Promise<T> {
    const response = await this.client.put<ApiResponse<T>>(url, data);
    return response.data.data;
  }

  async delete<T>(url: string): Promise<T> {
    const response = await this.client.delete<ApiResponse<T>>(url);
    return response.data.data;
  }

  async patch<T>(url: string, data?: unknown): Promise<T> {
    const response = await this.client.patch<ApiResponse<T>>(url, data);
    return response.data.data;
  }
}

export const apiClient = new ApiClient();
