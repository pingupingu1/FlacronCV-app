// D:\FlacronCV\lib\main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'features/home/presentation/welcome_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FlacronApp());
}

class FlacronApp extends StatelessWidget {
  const FlacronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlacronControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      onGenerateRoute: AppRouter.generate,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final user = authSnapshot.data;

        // Not logged in → landing page
        if (user == null) {
          return const WelcomeScreen();
        }

        // Logged in → fetch business doc for businessId + businessName
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('businesses')
              .where('ownerId', isEqualTo: user.uid)
              .limit(1)
              .get(),
          builder: (context, bizSnapshot) {
            if (bizSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              );
            }

            if (!bizSnapshot.hasData || bizSnapshot.data!.docs.isEmpty) {
              return const LoginScreen();
            }

            final doc = bizSnapshot.data!.docs.first;
            final businessId = doc.id;
            final data = doc.data() as Map<String, dynamic>;
            final businessName = (data['name'] ?? data['businessName'] ?? 'My Business') as String;

            return DashboardScreen(
              businessId: businessId,
              businessName: businessName,
            );
          },
        );
      },
    );
  }
}
