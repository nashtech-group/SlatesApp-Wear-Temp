import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/data/repositories/auth_repository/auth_repository.dart';
import 'data/repositories/auth_repository/auth_provider.dart';

class AppRepositories extends StatelessWidget {
  final Widget appBlocs;

  const AppRepositories({super.key, required this.appBlocs});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(providers: [
      RepositoryProvider(
          create: (context) => AuthRepository(authProvider: AuthProvider())),
    ], child: appBlocs);
  }
}
