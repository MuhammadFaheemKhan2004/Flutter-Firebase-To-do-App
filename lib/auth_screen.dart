import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String message = '';

  Future<void> signUp() async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user info to Firestore
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
      setState(() {
        message = '❌ Error: ${e.toString()}';
      });
    }
  }

  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        message = '✅ Signed in successfully!';
      });
    } catch (e) {
      setState(() {
        message = '❌ Error: ${e.toString()}';
      });
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => message = '❌ Google Sign-In aborted');
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Store user info in Firestore (if new)
      final docRef = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'email': userCredential.user!.email,
          'uid': userCredential.user!.uid,
          'createdAt': Timestamp.now(),
          'signInMethod': 'google',
        });
      }

      setState(() {
        message = '✅ Google Sign-In successful!';
      });
    } catch (e) {
      setState(() => message = '❌ Google Sign-In error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Auth')),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("You're signed in as: ${user.email}",
                      style: TextStyle(color: Colors.green)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();
                    },
                    child: Text("Logout"),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(onPressed: signUp, child: Text('Sign Up')),
                      ElevatedButton(onPressed: signIn, child: Text('Sign In')),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.login),
                    label: Text('Sign in with Google'),
                    onPressed: signInWithGoogle,
                  ),
                  if (message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(message,
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
