import 'dart:async';

import '../../../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc {
  final StreamController<AuthEvent> _eventController =
      StreamController<AuthEvent>();
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  AuthState _state = const AuthInitial();

  AuthBloc() {
    _eventController.stream.listen(_onEvent);
  }

  Stream<AuthState> get stream => _stateController.stream;
  AuthState get state => _state;

  void add(AuthEvent event) {
    _eventController.add(event);
  }

  Future<void> _onEvent(AuthEvent event) async {
    if (event is LoginRequested) {
      _emit(const AuthLoading());
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (event.email.isEmpty || event.password.isEmpty) {
        _emit(const AuthError('Email and password are required'));
        return;
      }

      _emit(
        AuthAuthenticated(
          User(id: '1', email: event.email, name: 'Authenticated User'),
        ),
      );
    }

    if (event is LogoutRequested) {
      _emit(const AuthInitial());
    }
  }

  void _emit(AuthState value) {
    _state = value;
    _stateController.add(value);
  }

  Future<void> close() async {
    await _eventController.close();
    await _stateController.close();
  }
}
