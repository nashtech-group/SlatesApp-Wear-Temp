import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlatesApp Wear'),
      ),
      body: const Center(
        child: Text('Welcome to the menu!'),
      ),
    );
  }
}
