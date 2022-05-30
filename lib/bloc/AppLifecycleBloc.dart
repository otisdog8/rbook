
import 'dart:ui';

import 'package:bloc/bloc.dart';

class AppLifecycleBloc extends Bloc<AppLifecycleState, AppLifecycleState> {
  AppLifecycleBloc() : super(AppLifecycleState.resumed) {
    on<AppLifecycleState>((event, emit) => emit(event));
  }
}