// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
// import 'package:food_app/models/app_user.dart'; // Import AppUser model

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // Get Firestore instance
  final _formKey = GlobalKey<FormState>();
  String _userEmail = '';
  String _userPassword = '';
  bool _isLogin = true;
  bool _isLoading = false;

  void _submitAuthForm(String email, String password) async {
    UserCredential userCredential;
    try {
      setState(() {
        _isLoading = true;
      });
      if (_isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // --- ADD THIS LOGIC FOR NEW USER SIGNUP ---
        if (userCredential.user != null) {
          // Create a new user document in Firestore immediately after signup
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': email,
                'name': email.split(
                  '@',
                )[0], // Use part of email as initial name
                'phoneNumber': null,
                'address': null,
                'createdAt': Timestamp.now(),
              });
          print(
            'New user profile created in Firestore for UID: ${userCredential.user!.uid}',
          );
        }
        // --- END ADDED LOGIC ---
      }
      print('Authentication successful! User: ${userCredential.user!.email}');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred, please check your credentials!';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _trySubmit() {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      _submitAuthForm(_userEmail.trim(), _userPassword.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: Theme.of(context).cardTheme.shape,
              elevation: Theme.of(context).cardTheme.elevation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Join Us!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const ValueKey('email'),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                        ),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _userEmail = value!;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('password'),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 7) {
                            return 'Password must be at least 7 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _userPassword = value!;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading) const CircularProgressIndicator(),
                      if (!_isLoading)
                        ElevatedButton(
                          onPressed: _trySubmit,
                          child: Text(_isLogin ? 'LOGIN' : 'SIGNUP'),
                        ),
                      if (!_isLoading)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'CREATE NEW ACCOUNT'
                                : 'I ALREADY HAVE AN ACCOUNT',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
