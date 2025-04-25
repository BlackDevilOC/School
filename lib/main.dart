import 'package:flutter/material.dart';
import 'routes.dart';
import 'screens/login_screen.dart';
// import 'package:academy_portal/LoginScreen.dart'; // <-- Add this line

void main() {
  runApp(AcademyApp());
}

class AcademyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academy Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.green,
          secondary: Colors.greenAccent,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      routes: Routes.getRoutes(),
    );
  }
}
