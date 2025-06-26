import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/data/repositories/auth_repository/auth_repository.dart';

class AppBlocs extends StatelessWidget {
  final Widget app;

  const AppBlocs({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => AuthBloc(
                authRepository: RepositoryProvider.of<AuthRepository>(context)))
      ],
      child: app,
    );
  }
}
