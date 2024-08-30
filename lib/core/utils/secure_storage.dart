import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/authorization.dart';
import 'dart:convert';

final storage = FlutterSecureStorage();

Future<void> saveAuthorizationData(Authorization authorization) async {
  await storage.write(key: 'authorization', value: jsonEncode(authorization.toJson()));
}

Future<Authorization?> loadAuthorizationData() async {
  String? data = await storage.read(key: 'authorization');
  if (data != null) {
    return Authorization.fromJson(jsonDecode(data));
  }
  return null;
}
