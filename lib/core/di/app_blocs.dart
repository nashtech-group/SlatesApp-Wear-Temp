import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/blocs/user/login_bloc.dart';
import '../../data/repositories/user_repository_impl.dart';

class AppBlocs extends StatelessWidget {
  final Widget app;

  const AppBlocs({Key? key, required this.app}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(
            userRepository: RepositoryProvider.of<UserRepositoryImpl>(context),
          ),
        ),
      ],
      child: app,
    );
  }
}
