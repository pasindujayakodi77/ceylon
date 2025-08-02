import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepo;

  AuthBloc({required this.authRepo}) : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepo.signInWithEmail(
          event.email,
          event.password,
        );
        emit(AuthSuccess(user!));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepo.signUpWithEmail(
          event.email,
          event.password,
        );
        emit(AuthSuccess(user!));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<SignOutRequested>((event, emit) async {
      await authRepo.signOut();
      emit(AuthInitial());
    });
  }
}
