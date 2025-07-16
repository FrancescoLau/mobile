// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/review_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => WorkoutProvider()),
        ChangeNotifierProvider(create: (context) => ReviewProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Workout App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}
