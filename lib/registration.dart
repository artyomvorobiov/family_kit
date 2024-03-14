import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package
import 'email_verification_page.dart';
import 'main_screen.dart';
import '/firebase_constants.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final _firebaseMessaging = FirebaseMessaging.instance;
  final TextEditingController _emailController = TextEditingController();
  String? token = '';
  final TextEditingController _emailResController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final uuid = Uuid();

  Future<void> _register(BuildContext context) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (auth.currentUser != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (ctx) => const EmailVerificationScreen()));
      }

      String familyId = uuid.v4();

      await _saveUserProfile(user, familyId);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль слишком простой.')),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Аккаунт для этой почты уже существует.')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();
    token = await _firebaseMessaging.getToken();
  }

  Future<dynamic> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = authResult.user;

    
      String familyId = uuid.v4(); 
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (!userSnapshot.exists) {
        await _saveUserProfile(user, familyId);
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Stack(children: [
                    MainScreen(),
                  ])),
        );
      } else {
        Navigator.of(context).pushNamed(
          MainScreen.routeName,
        );
      }
    } on Exception catch (e) {
      // TODO
      print('exception->$e');
    }
  }

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.of(context).pushNamed(
        MainScreen.routeName,
      );
   } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неправильная почта.')),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Неверный пароль. Восстановить пароль можно, нажав на "Забыли пароль?"')),
        );
      } else if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Пользователь не найден.')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _saveUserProfile(User? user, String familyId) async {
    if (user != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference users = firestore.collection('users');
      DocumentReference userDocument = users.doc(user.uid);
      await init();
      await userDocument.set({
        'email': user.email,
        'familyId': familyId,
        'firstName': '',
        'gender': '',
        'lastName': '',
        'tokenId': token,
        'familyId2': '',
        'familyId3': '',
        'isFamilyCreator1': true,
        'isFamilyCreator2': false,
        'isFamilyCreator3': false,
        'selectedFamily': 1,
        'family1Name': 'Семья 1',
        'family2Name': 'Семья 2',
        'family3Name': 'Семья 3',
      });
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Письмо с восстановлением пароля отправлено на вашу эл. почту.')),
      );
    } catch (e) {
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Ошибка при отправке письма с восстановлением пароля.')),
      );
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Семейная аптечка'),
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 10, 114, 1), 
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
            'assets/icn.png', 
            height: 150.0, 
            width: 150.0,  
          ),
            TextField(
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Эл. почта',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                SizedBox(width: 16.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });

                          setState(() {
                            _isLoading = false;
                          });
                          await _register(context);
                        },
                        child: const Text('Зарегистрироваться')),
                SizedBox(width: 50.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                  onPressed: _login,
                  child: Text('Войти'),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
              onPressed: () => signInWithGoogle(),
              child: Text('Войти с помощью Google'),
            ),
            SizedBox(height: 10.0),
            TextButton(
              onPressed: () async {
                // Показать диалоговое окно для ввода эл. почты
                String? email = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Восстановление пароля'),
                      content: TextField(
                        controller: _emailResController,
                        decoration: InputDecoration(
                            labelText: 'Введите свою эл. почту'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, _emailResController.text);
                          },
                          child: Text('Применить'),
                        ),
                      ],
                    );
                  },
                );
              
                if (email != null && email.isNotEmpty) {
                  print("YYYYYYYY");
                  await resetPassword(email);
                }
              },
              child: Text(
                'Забыли пароль?',
                style: TextStyle(
                    color: Colors.grey), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}
