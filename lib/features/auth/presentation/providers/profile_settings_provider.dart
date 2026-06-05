import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for push notification toggle state.
final pushNotificationProvider = StateProvider<bool>((ref) => true);

/// Provider for SMS alert toggle state.
final smsAlertProvider = StateProvider<bool>((ref) => false);
