import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:employee_dashboard_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/provider/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAFlc9bdsu7AKS7n9uDnnnvVmkI6Kb9LSc",
        appId: "1:725463305875:android:12b36b6c13b3c2af814766",
        messagingSenderId: "725463305875",
        projectId: "employee-dashboard-app-5f7ff",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          lazy: false, // Initialize immediately
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Employee Dashboard',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
