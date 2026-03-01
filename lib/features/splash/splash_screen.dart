// lib/features/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
      return;
    }

    // ── Logged in: fetch their businessId and businessName ──
    try {
      final snap = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        // No business yet — go to setup
        Navigator.pushReplacementNamed(context, RouteNames.businessSetup);
        return;
      }

      final businessDoc = snap.docs.first;
      final businessId = businessDoc.id;
      final businessName =
          businessDoc.data()['businessName'] as String? ?? 'My Business';

      Navigator.pushReplacementNamed(
        context,
        RouteNames.dashboard,
        arguments: {
          'businessId': businessId,
          'businessName': businessName,
        },
      );
    } catch (e) {
      if (!mounted) return;
      // On error, still try to go to dashboard with empty args
      Navigator.pushReplacementNamed(
        context,
        RouteNames.dashboard,
        arguments: {
          'businessId': '',
          'businessName': 'My Business',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[900]!,
              Colors.orange[700]!,
              Colors.orange[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.business_center_rounded,
                    size: 100, color: Colors.white),
                SizedBox(height: 40),
                Text('FlacronControl',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2)),
                SizedBox(height: 12),
                Text('Business Automation Platform',
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400)),
                SizedBox(height: 60),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 6),
                ),
                SizedBox(height: 40),
                Text('Initializing...',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
