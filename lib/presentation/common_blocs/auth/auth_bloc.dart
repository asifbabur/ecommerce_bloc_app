import 'package:bloc/bloc.dart';
import 'package:myezzecommerce_app/data/repository/repository.dart';
import 'package:myezzecommerce_app/presentation/common_blocs/auth/auth_event.dart';
import 'auth_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthRepository _authRepository = AppRepository.authRepository;

  AuthenticationBloc() : super(Uninitialized()) {
    on<AuthenticationStarted>(_onAuthenticationStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAuthenticationStarted(
      AuthenticationStarted event, Emitter<AuthenticationState> emit) async {
    try {
      bool isLoggedIn = _authRepository.isLoggedIn();

      // Simulating splash screen delay
      await Future.delayed(Duration(seconds: 3));

      if (isLoggedIn) {
        emit(Authenticated(_authRepository.loggedFirebaseUser));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthenticationState> emit) {
    emit(Authenticated(_authRepository.loggedFirebaseUser));
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthenticationState> emit) {
    _authRepository.logOut();
    emit(Unauthenticated());
  }
}
