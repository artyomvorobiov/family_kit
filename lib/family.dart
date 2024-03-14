import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'family_chat.dart';

class FamilyPage extends StatefulWidget {
  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  QuerySnapshot? familyMembers;
  late String familyId;
  DocumentSnapshot? userSnapshot;

  final uuid = Uuid();

  Future<List<Map<String, dynamic>>> _getFamilyMembers() async {
    User? user = _auth.currentUser;

    if (user != null) {
      familyId = await _getFamilyId(user.uid);
      userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (familyId.isNotEmpty) {
        familyMembers = await _firestore
            .collection('users')
            .where(Filter.or(
              Filter('familyId', isEqualTo: familyId),
              Filter('familyId2', isEqualTo: familyId),
              Filter('familyId3', isEqualTo: familyId),
            ))
            .get();

        return familyMembers!.docs
            .map((DocumentSnapshot doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }
    }

    return [];
  }

  Future<String?>? _getFamilyName() async {
    User? user = _auth.currentUser;

    if (user != null) {
      familyId = await _getFamilyId(user.uid);
      userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (userSnapshot != null) {
        return userSnapshot?['family${userSnapshot?['selectedFamily']}Name'] ?? '';
      } else {
        return '';
      }
      }
    return null;
    }


  

  Future<String> _getFamilyId(String userId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      if (userSnapshot['selectedFamily'] == 1) {
        return userSnapshot['familyId'];
      } else if (userSnapshot['selectedFamily'] == 2) {
        return userSnapshot['familyId2'];
      } else {
        return userSnapshot['familyId3'];
      }
    }

    return '';
  }

  Future<void> _deleteFamilyMember(
      String memberId, String selectedFamily) async {
    String newFamilyCode = uuid.v4();
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(memberId).get();
    if (userSnapshot.exists) {
      if (userSnapshot['familyId'] == familyId) {
        await _firestore.collection('users').doc(memberId).update({
          'familyId': newFamilyCode,
        });
      } else if (userSnapshot['familyId2'] == familyId) {
        await _firestore.collection('users').doc(memberId).update({
          'familyId2': newFamilyCode,
        });
      } else {
        await _firestore.collection('users').doc(memberId).update({
          'familyId3': newFamilyCode,
        });
      }
    }
    setState(() {});
  }

  bool isFamilyCreator() {
    return userSnapshot?['isFamilyCreator${userSnapshot?['selectedFamily']}'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFamilyMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Center(child: Image.asset('assets/loading.gif',
                        height: 200), );
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder<String?>(
                    future: _getFamilyName(),
                    builder: (context, familyNameSnapshot) {
                      if (familyNameSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: Image.asset('assets/loading.gif',
                        height: 200), );
                      } else if (familyNameSnapshot.hasError) {
                        return Text('Ошибка: ${familyNameSnapshot.error}');
                      } else if (familyNameSnapshot.hasData) {
                        return Text(
                          '${familyNameSnapshot.data}',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
  itemCount: snapshot.data!.length,
  itemBuilder: (context, index) {
    String? memberId = familyMembers?.docs[index].id;
    Map<String, dynamic> member = snapshot.data![index];
    String fullName =
        '${member['firstName'] == '' ? 'Имя' : member['firstName']} ${member['lastName'] == '' ? 'Фамилия' : member['lastName']}';
    String gender =
        member['gender'] == '' ? 'Пол' : member['gender'];
    bool isCurrentUser = memberId == _auth.currentUser?.uid;

    return ListTile(
      title: Text(
          fullName.isNotEmpty ? fullName : 'Нет имени'),
      subtitle: Text('Пол: $gender'),
      trailing: isCurrentUser
          ? SizedBox.shrink()
          : Builder(
              builder: (context) {
                if (isFamilyCreator()) {
                  return IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      bool confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Подтвердите удаление'),
                          content: Text(
                              'Вы точно хотите удалить $fullName из семьи?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: Text('Удалить'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        await _deleteFamilyMember(memberId!,
                            member['selectedFamily'].toString());

                      }
                    },
                  );
                } else {
                  return SizedBox
                      .shrink();
                }
              },
            ),
    );
  },
),


                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1),
  ),
                  onPressed: () async {
                    User? user = _auth.currentUser;
                    String familyId = await _getFamilyId(user!.uid);
                    // Передача _familyId при переходе на экран чата
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FamilyChatScreen(familyId: familyId),
                      ),
                    );
                  },
                  child: Text('Чат с семьей'),
                ),
              ],
            );
          } else {
            return Center(child: Text('Нет членов семьи'));
          }
        },
      ),
    );
  }
}
