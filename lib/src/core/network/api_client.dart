import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../errors/app_exceptions.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final Dio _dio;
  final String baseUrl;

  ApiClient({
    required this.baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout ?? Duration(seconds: AppConstants.apiTimeoutSeconds),
            receiveTimeout: receiveTimeout ?? Duration(seconds: AppConstants.apiTimeoutSeconds),
            sendTimeout: sendTimeout ?? Duration(seconds: AppConstants.apiTimeoutSeconds),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('🚀 REQUEST[${options.method}] ${options.path}');
            print('   Headers: ${options.headers}');
            if (options.data != null) {
              print('   Data: ${options.data}');
            }
            if (options.queryParameters.isNotEmpty) {
              print('   Query: ${options.queryParameters}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ RESPONSE[${response.statusCode}] ${response.requestOptions.path}');
            print('   Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('❌ ERROR[${error.response?.statusCode}] ${error.requestOptions.path}');
            print('   Message: ${error.message}');
            print('   Type: ${error.type}');
            if (error.response?.data != null) {
              print('   Data: ${error.response?.data}');
            }
          }
          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          // Don't reject with mapped exception, let the original error pass through
          // The mapped exception is available for error handling in the UI layer
          return handler.next(error);
        },
      ),
    );
  }

  AppException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Bağlantı zaman aşımına uğradı',
          originalError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.connectionError:
        return NoInternetException(
          message: 'İnternet bağlantısı yok veya sunucuya ulaşılamıyor',
          originalError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Sunucu hatası oluştu';

        if (data is Map<String, dynamic>) {
          message = data['message']?.toString() ?? data['error']?.toString() ?? message;
        } else if (data is String) {
          message = data;
        }

        switch (statusCode) {
          case 400:
            return ValidationException(
              message: message,
              fieldErrors: _extractFieldErrors(data),
              originalError: error,
              stackTrace: error.stackTrace,
            );
          case 401:
            return UnauthorizedException(
              message: message,
              originalError: error,
              stackTrace: error.stackTrace,
            );
          case 403:
            return ForbiddenException(
              message: message,
              originalError: error,
              stackTrace: error.stackTrace,
            );
          case 404:
            return NotFoundException(
              message: message,
              originalError: error,
              stackTrace: error.stackTrace,
            );
          case 429:
            final retryAfter = error.response?.headers.value('Retry-After');
            return RateLimitException(
              message: message,
              retryAfter: retryAfter != null ? Duration(seconds: int.tryParse(retryAfter) ?? 0) : null,
              originalError: error,
              stackTrace: error.stackTrace,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              message: message,
              statusCode: statusCode,
              originalError: error,
              stackTrace: error.stackTrace,
            );
          default:
            return ServerException(
              message: message,
              statusCode: statusCode,
              originalError: error,
              stackTrace: error.stackTrace,
            );
        }
      case DioExceptionType.cancel:
        return UnknownException(
          message: 'İstek iptal edildi',
          code: 'CANCELLED',
          originalError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') == true) {
          return NoInternetException(
            originalError: error,
            stackTrace: error.stackTrace,
          );
        }
        return UnknownException(
          message: error.message ?? 'Bilinmeyen bir hata oluştu',
          originalError: error,
          stackTrace: error.stackTrace,
        );
    }
  }

  Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['errors'] is Map) {
        return (data['errors'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            value is List ? value.map((e) => e.toString()).toList() : [value.toString()],
          ),
        );
      }
      if (data['details'] is Map) {
        return (data['details'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            value is List ? value.map((e) => e.toString()).toList() : [value.toString()],
          ),
        );
      }
    }
    return null;
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  void setCustomHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}