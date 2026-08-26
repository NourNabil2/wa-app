// lib/features/home/presentation/cubit/home_ui_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeUiState {
  final bool isBookingLoading;
  final int? selectedClinicId; // Changed from String to int

  const HomeUiState({
    this.isBookingLoading = false,
    this.selectedClinicId,
  });

  HomeUiState copyWith({
    bool? isBookingLoading,
    int? selectedClinicId,
    bool clearSelection = false,
  }) {
    return HomeUiState(
      isBookingLoading: isBookingLoading ?? this.isBookingLoading,
      selectedClinicId: clearSelection ? null : (selectedClinicId ?? this.selectedClinicId),
    );
  }
}

class HomeUiCubit extends Cubit<HomeUiState> {
  HomeUiCubit() : super(const HomeUiState());

  void startBooking(int clinicId) { // Changed from String to int
    emit(state.copyWith(
      isBookingLoading: true,
      selectedClinicId: clinicId,
    ));
  }

  void finishBooking() {
    emit(state.copyWith(
      isBookingLoading: false,
      clearSelection: true,
    ));
  }

  void cancelBooking() {
    emit(state.copyWith(
      isBookingLoading: false,
      clearSelection: true,
    ));
  }
}