import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/app_blocs.dart';
import 'package:slates_app_wear/app_repositories.dart';
import 'package:slates_app_wear/routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppRepositories(
      appBlocs: AppBlocs(
        app: MaterialApp(
          title: AppConstants.appTitle,
        
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: '/',
        ),
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    //Handle navigation to different screens based index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
      ),
      body: Center(
        child: Text(
          'Selected page index: $_selectedIndex',
          style: const TextStyle(fontSize: 24),
        ),
      ),

    );
  }
}
