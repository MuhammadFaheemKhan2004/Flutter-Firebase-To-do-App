import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_screen.dart'; // 👈 Create this next

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: AuthScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
