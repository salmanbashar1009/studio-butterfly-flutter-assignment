enum SmsStatus {
  accepted,
  sent,
  delivered,
  failed;

  static SmsStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return SmsStatus.accepted;
      case 'SENT':
        return SmsStatus.sent;
      case 'DELIVERED':
        return SmsStatus.delivered;
      case 'FAILED':
        return SmsStatus.failed;
      default:
        throw ArgumentError('Unknown SMS Status: $status');
    }
  }

  String toApiString() => name.toUpperCase();
  
  String get displayLabel {
    switch (this) {
      case SmsStatus.accepted:
        return 'Accepted';
      case SmsStatus.sent:
        return 'Sent';
      case SmsStatus.delivered:
        return 'Delivered';
      case SmsStatus.failed:
        return 'Failed';
    }
  }
}
