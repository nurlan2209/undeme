import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const UndemeApp());
}

class UndemeApp extends StatelessWidget {
  const UndemeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Undeme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro',
      ),
      home: const AuthScreen(),
    );
  }
}
