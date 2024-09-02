import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/presentation/blocs/login_bloc.dart';
import 'package:slates_app_wear/presentation/blocs/login_event.dart';
import 'package:slates_app_wear/presentation/blocs/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _employeeId = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlatesApp Wear'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Navigator.pushReplacementNamed(context, '/menu');
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Employee ID',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _employeeId = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              TextField(
                decoration: const InputDecoration(
                  labelText: '4-Digit PIN',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (value) {
                  if (value.length <= 4) {
                    setState(() {
                      _password = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_employeeId.isNotEmpty && _password.length == 4) {
                    context.read<LoginBloc>().add(LoginSubmitted(
                        password: _password, employeeId: _employeeId));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Please enter a valid Employee ID and PIN')),
                    );
                  }
                },
                child: const Text('Login'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
