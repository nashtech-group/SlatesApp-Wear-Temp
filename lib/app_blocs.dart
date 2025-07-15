import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/blocs/checkpoint_bloc/checkpoint_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/blocs/notification_bloc/notification_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/data/repositories/auth_repository/auth_repository.dart';
import 'package:slates_app_wear/data/repositories/roster_repository/roster_repository.dart';

class AppBlocs extends StatelessWidget {
  final Widget app;

  const AppBlocs({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => AuthBloc(
                authRepository: RepositoryProvider.of<AuthRepository>(context))),
       BlocProvider(
          create: (context) => RosterBloc(
            rosterRepository: RepositoryProvider.of<RosterRepository>(context),
          ),
        ),
        BlocProvider(
          create: (context) => CheckpointBloc(),
        ),
        BlocProvider(
          create: (context) => LocationBloc(),
        ),
        BlocProvider(
          create: (context) => NotificationBloc(),
        ),
      ],
      child: app,
    );
  }
}
