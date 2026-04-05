import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/storage/secure_storage.dart';

enum UserRole { petOwner, provider }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatar,
  });
}

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    Future.microtask(_loadFromStorage);
    return null;
  }

  Future<void> _loadFromStorage() async {
    final storage = ref.read(secureStorageProvider);
    final userId = await storage.read(StorageKeys.userId);
    final roleStr = await storage.read(StorageKeys.userRole);
    if (userId != null && roleStr != null) {
      state = UserModel(
        id: userId,
        name: '',
        phone: '',
        role: UserRole.values.byName(roleStr),
      );
    }
  }

  Future<void> login(UserModel user) async {
    state = user;
    final storage = ref.read(secureStorageProvider);
    await storage.write(StorageKeys.userId, user.id);
    await storage.write(StorageKeys.userRole, user.role.name);
  }

  Future<void> logout() async {
    state = null;
    final storage = ref.read(secureStorageProvider);
    await storage.deleteAll();
  }
}

final userNotifierProvider =
    NotifierProvider<UserNotifier, UserModel?>(UserNotifier.new);
