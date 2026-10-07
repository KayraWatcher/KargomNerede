abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = 'İstek zaman aşımına uğradı',
    super.code = 'TIMEOUT',
    super.originalError,
    super.stackTrace,
  });
}

class NoInternetException extends NetworkException {
  const NoInternetException({
    super.message = 'İnternet bağlantısı yok',
    super.code = 'NO_INTERNET',
    super.originalError,
    super.stackTrace,
  });
}

class ServerException extends NetworkException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

class UnauthorizedException extends ServerException {
  const UnauthorizedException({
    super.message = 'Oturum süresi doldu, lütfen tekrar giriş yapın',
    super.code = 'UNAUTHORIZED',
    super.statusCode = 401,
    super.originalError,
    super.stackTrace,
  });
}

class ForbiddenException extends ServerException {
  const ForbiddenException({
    super.message = 'Bu işlem için yetkiniz yok',
    super.code = 'FORBIDDEN',
    super.statusCode = 403,
    super.originalError,
    super.stackTrace,
  });
}

class NotFoundException extends ServerException {
  const NotFoundException({
    super.message = 'Kaynak bulunamadı',
    super.code = 'NOT_FOUND',
    super.statusCode = 404,
    super.originalError,
    super.stackTrace,
  });
}

class RateLimitException extends ServerException {
  final Duration? retryAfter;

  const RateLimitException({
    super.message = 'Çok fazla istek gönderildi, lütfen bekleyin',
    super.code = 'RATE_LIMITED',
    super.statusCode = 429,
    this.retryAfter,
    super.originalError,
    super.stackTrace,
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });
}

class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class AuthorizationException extends AppException {
  const AuthorizationException({
    required super.message,
    super.code = 'AUTHZ_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class TrackingException extends AppException {
  final String? trackingNumber;
  final String? carrierCode;

  const TrackingException({
    required super.message,
    super.code,
    this.trackingNumber,
    this.carrierCode,
    super.originalError,
    super.stackTrace,
  });
}

class CarrierNotSupportedException extends TrackingException {
  const CarrierNotSupportedException({
    required super.trackingNumber,
    super.message = 'Bu kargo firması desteklenmiyor',
    super.code = 'CARRIER_NOT_SUPPORTED',
    super.carrierCode,
    super.originalError,
    super.stackTrace,
  });
}

class TrackingNumberInvalidException extends TrackingException {
  const TrackingNumberInvalidException({
    required super.trackingNumber,
    super.message = 'Geçersiz takip numarası',
    super.code = 'INVALID_TRACKING_NUMBER',
    super.carrierCode,
    super.originalError,
    super.stackTrace,
  });
}

class TrackingNotFoundException extends TrackingException {
  const TrackingNotFoundException({
    required super.trackingNumber,
    super.message = 'Bu takip numarası için bilgi bulunamadı',
    super.code = 'TRACKING_NOT_FOUND',
    super.carrierCode,
    super.originalError,
    super.stackTrace,
  });
}

class ProviderUnavailableException extends TrackingException {
  final String providerName;

  const ProviderUnavailableException({
    required this.providerName,
    super.message = 'Takip servisi şu anda kullanılamıyor',
    super.code = 'PROVIDER_UNAVAILABLE',
    super.trackingNumber,
    super.carrierCode,
    super.originalError,
    super.stackTrace,
  });
}

class ConfigurationException extends AppException {
  const ConfigurationException({
    required super.message,
    super.code = 'CONFIG_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class NotificationException extends AppException {
  const NotificationException({
    required super.message,
    super.code = 'NOTIFICATION_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

AppException handleError(dynamic error, StackTrace? stackTrace) {
  if (error is AppException) return error;

  if (error is FormatException) {
    return ValidationException(
      message: 'Veri formatı hatası: ${error.message}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  if (error is TypeError) {
    return UnknownException(
      message: 'Tip hatası: ${error.toString()}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  if (error is StateError) {
    return UnknownException(
      message: 'Durum hatası: ${error.message}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  if (error is ArgumentError) {
    return ValidationException(
      message: 'Argüman hatası: ${error.message}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  if (error is RangeError) {
    return ValidationException(
      message: 'Aralık hatası: ${error.message}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  return UnknownException(
    message: error?.toString() ?? 'Bilinmeyen bir hata oluştu',
    originalError: error,
    stackTrace: stackTrace,
  );
}

String getUserFriendlyMessage(AppException exception) {
  switch (exception.runtimeType) {
    case NoInternetException:
      return 'İnternet bağlantınızı kontrol edip tekrar deneyin.';
    case TimeoutException:
      return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
    case UnauthorizedException:
      return 'Oturumunuz sona erdi. Lütfen uygulamayı yeniden başlatın.';
    case ForbiddenException:
      return 'Bu işlem için gerekli izniniz bulunmuyor.';
    case NotFoundException:
      return 'Aradığınız bilgiye ulaşılamadı.';
    case RateLimitException:
      return 'Çok hızlı işlem yapıyorsunuz. Lütfen bir süre bekleyin.';
    case CarrierNotSupportedException:
      return 'Bu kargo firması henüz desteklenmiyor. Takip numarasını manuel ekleyebilirsiniz.';
    case TrackingNumberInvalidException:
      return 'Takip numarası formatı hatalı. Lütfen kontrol edin.';
    case TrackingNotFoundException:
      return 'Bu takip numarası ile eşleşen kargo bulunamadı.';
    case ProviderUnavailableException:
      return 'Takip servisi şu anda kullanılamıyor. Daha sonra tekrar deneyin.';
    case CacheException:
      return 'Önbellek hatası. Uygulamayı yeniden başlatmayı deneyin.';
    case DatabaseException:
      return 'Veritabanı hatası. Uygulamayı yeniden başlatmayı deneyin.';
    case NotificationException:
      return 'Bildirim ayarlarınızı kontrol edin.';
    case ConfigurationException:
      return 'Uygulama yapılandırmasında bir sorun var. Yeniden kurmayı deneyin.';
    case StorageException:
      return 'Depolama alanında sorun var. Boş alan oluşturup tekrar deneyin.';
    default:
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}