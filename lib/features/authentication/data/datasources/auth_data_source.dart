import '../../domain/entities/app_user.dart';
import '../models/auth_models.dart';

abstract interface class AuthDataSource {
  Future<LoginResponse> login(String email, String password);
  Future<AppUser> me();
  bool get isDemo;
}
