// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'package:food_app/screens/auth_screen.dart';
import 'package:food_app/screens/home_screen.dart';
import 'package:food_app/providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => CartProvider())],
      child: MaterialApp(
        title: 'Food Delivery App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF4A148C),
          colorScheme:
              ColorScheme.fromSwatch(
                primarySwatch: MaterialColor(0xFF4A148C, const <int, Color>{
                  50: Color(0xFFF3E5F5),
                  100: Color(0xFFE1BEE7),
                  200: Color(0xFFCE93D8),
                  300: Color(0xFFBA68C8),
                  400: Color(0xFFAB47BC),
                  500: Color(0xFF9C27B0),
                  600: Color(0xFF8E24AA),
                  700: Color(0xFF7B1FA2),
                  800: Color(0xFF6A1B9A),
                  900: Color(0xFF4A148C),
                }),
              ).copyWith(
                secondary: Colors.tealAccent[400],
                error: Colors.redAccent,
                background: Colors.grey[50],
              ),
          textTheme: TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A148C),
            ),
            headlineMedium: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A148C),
            ),
            headlineSmall: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A148C),
            ),
            titleLarge: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleMedium: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.black87),
            bodyMedium: const TextStyle(fontSize: 14.0, color: Colors.black54),
            labelLarge: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4A148C),
            foregroundColor: Colors.white,
            elevation: 4,
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A148C),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4A148C), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // --- BEGIN CUSTOM LOADING STATE ---
              return Scaffold(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor, // Use your primary color for background
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // You can add an Image.asset for your app logo here
                      // Example: Image.asset('assets/images/app_logo.png', width: 100, height: 100),
                      Icon(
                        Icons.fastfood,
                        size: 100,
                        color: Colors.white,
                      ), // Placeholder logo icon
                      const SizedBox(height: 20),
                      Text(
                        'Food Delivery App',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      CircularProgressIndicator(
                        color: Colors.white,
                      ), // White spinner
                    ],
                  ),
                ),
              );
              // --- END CUSTOM LOADING STATE ---
            }
            if (snapshot.hasData) {
              return const HomeScreen();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
