import 'package:bloc/bloc.dart';
import 'package:myezzecommerce_app/data/repository/repository.dart';
import 'package:myezzecommerce_app/presentation/screens/register/register/bloc.dart';
import 'package:myezzecommerce_app/utils/validator.dart';
import 'package:rxdart/rxdart.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository = AppRepository.authRepository;

  RegisterBloc() : super(RegisterState.empty()) {
    on<EmailChanged>(_onEmailChanged, transformer: debounce());
    on<PasswordChanged>(_onPasswordChanged, transformer: debounce());
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged,
        transformer: debounce());
    on<Submitted>(_onFormSubmitted);
  }

  EventTransformer<T> debounce<T>() {
    return (events, mapper) =>
        events.debounceTime(Duration(milliseconds: 300)).switchMap(mapper);
  }

  void _onEmailChanged(EmailChanged event, Emitter<RegisterState> emit) {
    emit(state.update(isEmailValid: UtilValidators.isValidEmail(event.email)));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<RegisterState> emit) {
    emit(state.update(
        isPasswordValid: UtilValidators.isValidPassword(event.password)));
  }

  void _onConfirmPasswordChanged(
      ConfirmPasswordChanged event, Emitter<RegisterState> emit) {
    var isConfirmPasswordValid =
        UtilValidators.isValidPassword(event.confirmPassword);
    var isMatched = event.password.isNotEmpty
        ? event.password == event.confirmPassword
        : true;
    emit(state.update(
        isConfirmPasswordValid: isConfirmPasswordValid && isMatched));
  }

  Future<void> _onFormSubmitted(
      Submitted event, Emitter<RegisterState> emit) async {
    try {
      emit(RegisterState.loading());
      await _authRepository.signUp(event.newUser, event.password);
      bool isLoggedIn = _authRepository.isLoggedIn();
      if (isLoggedIn) {
        emit(RegisterState.success());
      } else {
        emit(RegisterState.failure(_authRepository.authException));
      }
    } catch (e) {
      emit(RegisterState.failure("Register Failure"));
    }
  }
}
