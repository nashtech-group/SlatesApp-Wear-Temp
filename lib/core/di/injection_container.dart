import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/use_cases/get_user.dart';
import '../../domain/use_cases/login_user.dart';
import '../../domain/use_cases/logout_user_dart';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/network_info.dart';

final GetIt injector = GetIt.instance;

void init() {

  injector.registerLazySingleton(() => http.Client());
  injector.registerLazySingleton(() => Connectivity());
  injector.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(client: injector()));

  // Register use cases
  injector.registerLazySingleton(() => GetUser(injector()));
  injector.registerLazySingleton(() => LoginUser(injector()));
  injector.registerLazySingleton(() => LogoutUser(injector()));

   // Register network info utility with Connectivity dependency
  injector.registerLazySingleton(() => NetworkInfo(injector()));

}
