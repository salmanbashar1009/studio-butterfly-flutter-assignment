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
  SmsAuthenticationException(super.message);
}

/// Represents HTTP 403 Forbidden - when a token is valid but doesn't have access to the tenant.
class SmsForbiddenException extends SmsException {
  SmsForbiddenException(super.message);
}

class SmsUpstreamException extends SmsException {
  SmsUpstreamException(super.message);
}

class SmsNetworkException extends SmsException {
  SmsNetworkException(super.message);
}

class SmsServerException extends SmsException {
  SmsServerException(super.message);
}
