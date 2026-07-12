class SmsException implements Exception {
  final String message;
  SmsException(this.message);

  @override
  String toString() => message;
}

class SmsValidationException extends SmsException {
  final String errorCode;
  SmsValidationException(this.errorCode, String message) : super(message);
}

class SmsRateLimitException extends SmsException {
  final int? retryAfterSeconds;
  SmsRateLimitException({
    this.retryAfterSeconds,
    String message = 'Rate limit exceeded. Please retry later.',
  }) : super(message);
}

class SmsAuthenticationException extends SmsException {
  SmsAuthenticationException(String message) : super(message);
}

/// Represents HTTP 403 Forbidden - when a token is valid but doesn't have access to the tenant.
class SmsForbiddenException extends SmsException {
  SmsForbiddenException(String message) : super(message);
}

class SmsUpstreamException extends SmsException {
  SmsUpstreamException(String message) : super(message);
}

class SmsNetworkException extends SmsException {
  SmsNetworkException(String message) : super(message);
}

class SmsServerException extends SmsException {
  SmsServerException(String message) : super(message);
}
