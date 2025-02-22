import 'package:bloc/bloc.dart';
import 'package:ecommerce_bloc_app/data/repository/app_repository.dart';
import 'package:ecommerce_bloc_app/data/repository/repository.dart';
import 'package:ecommerce_bloc_app/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository = AppRepository.authRepository;

  LoginBloc() : super(LoginState.empty()) {
    on<EmailChanged>(_onEmailChanged, transformer: debounce());
    on<PasswordChanged>(_onPasswordChanged, transformer: debounce());
    on<LoginWithCredential>(_onLoginWithCredential);
  }

  EventTransformer<T> debounce<T>() {
    return (events, mapper) => events.debounceTime(Duration(milliseconds: 300)).switchMap(mapper);
  }

  void _onEmailChanged(EmailChanged event, Emitter<LoginState> emit) {
    emit(state.update(isEmailValid: UtilValidators.isValidEmail(event.email)));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<LoginState> emit) {
    emit(state.update(isPasswordValid: UtilValidators.isValidPassword(event.password)));
  }

  Future<void> _onLoginWithCredential(
      LoginWithCredential event, Emitter<LoginState> emit) async {
    try {
      emit(LoginState.logging());
      await _authRepository.logInWithEmailAndPassword(event.email, event.password);
      bool isLoggedIn = _authRepository.isLoggedIn();
      if (isLoggedIn) {
        emit(LoginState.success());
      } else {
        emit(LoginState.failure(_authRepository.authException));
      }
    } catch (e) {
      emit(LoginState.failure("Login Failure"));
    }
  }
}