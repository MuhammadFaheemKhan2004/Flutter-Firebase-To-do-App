import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'todo_screen.dart'; // Navigate to main app
import 'package:shared_preferences/shared_preferences.dart';


class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String message = '';

  Future<void> signUpWithEmail() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': userCredential.user!.email,
        'uid': userCredential.user!.uid,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        message = '✅ Registered & saved to Firestore!';
      });
    } catch (e) {
      print("❌ SIGN UP ERROR: $e");
      setState(() {
        message = '❌ Error: ${e.toString()}';
      });
    }
  }

 Future<void> signInWithEmail() async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TodoScreen()),
    );
  } catch (e) {
    print("❌ SIGN IN ERROR: $e");
    setState(() {
      message = '❌ Error: ${e.toString()}';
    });
  }
}

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);

      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'email': userCredential.user!.email,
          'uid': userCredential.user!.uid,
          'createdAt': Timestamp.now(),
        });
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => TodoScreen()));
          final prefs = await SharedPreferences.getInstance();
await prefs.setBool('isLoggedIn', true);

    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firebase Auth")),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user != null) {
            // Already signed in
            return TodoScreen();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: signUpWithEmail, child: Text("Sign Up")),
                    ElevatedButton(
                        onPressed: signInWithEmail, child: Text("Sign In")),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.login),
                  label: Text("Sign In with Google"),
                  onPressed: signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                ),
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(message,
                        style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
