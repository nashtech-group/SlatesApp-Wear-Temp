import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
      ),
      body: const Center(
        child: Text('Welcome to the menu!'),
      ),
    );
  }
}
