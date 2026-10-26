import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

final currentAccountIdProvider = Provider<String?>((ref) =>
    ref.watch(authControllerProvider.select((state) => state.user?.id)));
