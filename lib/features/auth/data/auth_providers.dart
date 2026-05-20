import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reporting/data/report_providers.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient);
});

final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(authRepositoryProvider).getUser();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider).asData?.value;
  return user?['id']?.toString();
});
