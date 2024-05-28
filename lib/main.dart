import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import 'medicine/medicine_provider.dart';
import 'family/family_provider.dart';
import 'auth/registration.dart';
import 'main_screen.dart';

Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.notification?.body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Семейная аптечка',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isLoggedIn ? MainScreen() : RegistrationScreen();
        },
      ),
      routes: {
        '/registration': (context) => RegistrationScreen(),
        '/main': (context) => MainScreen(),
        '/list': (context) => MedicineList(),
      },
    );
  }
}
