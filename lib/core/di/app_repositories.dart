import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/utils/network_info.dart';
import 'package:slates_app_wear/data/repositories/user_repository_impl.dart';
import '../../data/providers/user_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppRepositories extends StatelessWidget {
  final Widget appBlocs;

  const AppRepositories({Key? key, required this.appBlocs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(providers: [
      RepositoryProvider<UserRepositoryImpl>(
        create: (context) => UserRepositoryImpl(
          userProvider: UserProvider(client: http.Client()),
          networkInfo: NetworkInfo(Connectivity()),
        ),
      ),
    ], child: appBlocs);
  }
}
