import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/registration');
  }

  void _contactSupport() async {
    final url = Uri.parse(
        "mailto:vorobev.artem2003@gmail.com?subject=Семейная%20аптечка&body=Добрый%20день!");

    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/loading.gif',
            height: 200,
          ),
          SizedBox(height: 50),
          ElevatedButton.icon(
            onPressed: _contactSupport,
            icon: Icon(Icons.mail),
            label: Text(
              'Связаться с поддержкой',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              primary: Color.fromARGB(255, 10, 114, 1), 
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _signOut(context),
            icon: Icon(Icons.exit_to_app),
            label: Text(
              'Выйти из аккаунта',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              primary: Color.fromARGB(255, 10, 114, 1), 
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
