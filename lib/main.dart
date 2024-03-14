// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '/registration.dart';
import 'medicine_provider.dart';
import 'drug_list.dart';
import 'main_screen.dart';
Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.notification?.body);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  runApp( ChangeNotifierProvider(
      create: (context) => MedicineProvider(),
      child: MyApp(),
    ),);
}

final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationScreen())); // Возвращаемся на экран регистрации после выхода
  }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Семейная аптечка',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: FirebaseAuth.instance.currentUser != null
          ? MainScreen()
          : RegistrationScreen(),
       routes: {
    '/registration': (context) => RegistrationScreen(),
    '/main': (context) => MainScreen(),
    '/list': (context) => MedicineList(),
  },
    );
  }
}


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главный экран'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Добро пожаловать!'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: Text('Выйти из аккаунта'),
            ),
          ],
        ),
      ),
    );
    
  }
