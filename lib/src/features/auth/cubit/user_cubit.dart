import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final AuthService _authService;

  UserCubit({
    AuthService? authService,
  })  : _authService = authService ?? AuthService(),
        super(const UserInitial());

  Future<void> fetchProfile() async {
    try {
      emit(const UserLoading());
      final result = await _authService.getProfile();
      if (result['success'] == true && result['profile'] != null) {
        final profileData = result['profile'] as Map<String, dynamic>;
        final profile = ProfileModel.fromJson(profileData);
        emit(UserLoaded(profile: profile));
      } else {
        emit(UserError(
          message: result['message'] ?? 'errorProfileFetchFailed',
        ));
      }
    } catch (e) {
      emit(UserError(
        message: 'errorProfileFetch',
      ));
    }
  }

  void resetUserState() {
    emit(const UserInitial());
  }
}
