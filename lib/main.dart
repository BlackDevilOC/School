import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sxfbiywdpfmkucofnsbj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4ZmJpeXdkcGZta3Vjb2Zuc2JqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNzU2ODEsImV4cCI6MjA2MTk1MTY4MX0.8n9ncMDw5ymwmUwc7Bi1cJauO2tp3B1FPK9b7E9r-nI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academy Portal',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: Routes.login,
      routes: Routes.getRoutes(),
    );
  }
}
