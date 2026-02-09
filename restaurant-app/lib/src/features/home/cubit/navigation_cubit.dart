import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/features/home/cubit/navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState.initial());

  void changeTab(int index) {
    if (state.currentIndex == index) return;
    emit(state.copyWith(currentIndex: index));
  }

  void resetToHome() {
    emit(const NavigationState.initial());
  }
}
