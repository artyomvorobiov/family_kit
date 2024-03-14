import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:testiks/registration.dart';

import '/firebase_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser?.sendEmailVerification();
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Почта подтверждена")));
      timer?.cancel();
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => Stack(children: [
    MainScreen(),
  ])));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        title: Text('Подтверждение почты'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            User? user = _auth.currentUser;
             if (user != null) {
                await _firestore.collection('users').doc(user.uid).delete();
             }
            FirebaseAuth.instance.currentUser?.delete();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Stack(
                  children: [
                    RegistrationScreen(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 35),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Проверьте свою\nпочту',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Center(
                  child: Text(
                    'Мы отправили письмо на  ${auth.currentUser?.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/loading.gif',
                  height: 200,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Center(
                  child: Text(
                    'Подтверждение почты....',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 57),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ElevatedButton(
                  child: const Text('Отправить повторно'),
                  onPressed: () {
                    try {
                      FirebaseAuth.instance.currentUser
                          ?.sendEmailVerification();
                    } catch (e) {
                      debugPrint('$e');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}