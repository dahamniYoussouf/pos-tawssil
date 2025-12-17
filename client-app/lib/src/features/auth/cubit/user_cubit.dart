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
      if (isClosed) return;
      emit(const UserLoading());
      final result = await _authService.getProfile();
      if (isClosed) return;
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
      if (isClosed) return;
      emit(UserError(
        message: 'errorProfileFetch',
      ));
    }
  }

  void resetUserState() {
    if (isClosed) return;
    emit(const UserInitial());
  }

  ProfileModel? get profileModel {
    if (state is UserLoaded) {
      return (state as UserLoaded).profile;
    }
    return null;
  }
}
