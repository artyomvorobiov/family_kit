import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'favourite_drugs.dart';
import 'my_drugs.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _surnameController = TextEditingController();
  int selectedFamily = 1;
  List<TextEditingController> familyIdControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _family2NameController = TextEditingController();
  final TextEditingController _family3NameController = TextEditingController();
  var old1 = '';
  var old2 = '';
  var old3 = '';
  List<bool> isCreator = [false, false, false];
  final TextEditingController _genderController = TextEditingController();
  Future<String?> _getFamilyId() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (userSnapshot.exists) {
        if (userSnapshot['selectedFamily'] == 1) {
            return userSnapshot['familyId'];
        }
        else if (userSnapshot['selectedFamily'] == 2) {
            return userSnapshot['familyId2'];
        }
        else {
          return userSnapshot['familyId3'];
        }
      }
    }

    return null;
  }
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: familyIdControllers.length, vsync: this);
  }

Future<void> updateDrugsFamilyId(String oldFamilyId, String newFamilyId, String userId) async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('drugs')
      .where('familyId', isEqualTo: oldFamilyId)
      .where('addedBy', isEqualTo: userId)
      .get();

  List<DocumentSnapshot> documents = querySnapshot.docs;

  for (DocumentSnapshot document in documents) {
    await FirebaseFirestore.instance
        .collection('drugs')
        .doc(document.id)
        .update({'familyId': newFamilyId});
  }
}

  Future<void> _updatePersonalData(BuildContext context) async {
  User? user = _auth.currentUser;

  if (user != null) {
    await _firestore.collection('users').doc(user.uid).update({
      'gender': _genderController.text,
      'firstName': _nameController.text,
      'lastName': _surnameController.text,
      'familyId': familyIdControllers[0].text,
      'familyId2': familyIdControllers[1].text,
      'familyId3': familyIdControllers[2].text,
      'isFamilyCreator1': isCreator[0], 
      'isFamilyCreator2': isCreator[1], 
      'isFamilyCreator3': isCreator[2], 
      'selectedFamily': selectedFamily,
      'family1Name': _familyNameController.text,
      'family2Name': _family2NameController.text,
      'family3Name': _family3NameController.text,

    });
    if (old1 != '' && old1 != familyIdControllers[0].text) {
       await updateDrugsFamilyId(old1, familyIdControllers[0].text, user.uid);
    }
    if (old2 != '' && old2 != familyIdControllers[1].text) {
       await updateDrugsFamilyId(old2, familyIdControllers[1].text, user.uid);
    }
     if (old3 != '' && old3 != familyIdControllers[2].text) {
       await updateDrugsFamilyId(old3, familyIdControllers[2].text, user.uid);
    }
    setState(() {});
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Личные данные обновлены')),
    );
  }
}

void _changeSelectedFamily(int index) {
  setState(() {
    selectedFamily = index + 1;
  });

  _updateSelectedFamily(index + 1);
}

Future<void> _updateSelectedFamily(int familyIndex) async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'selectedFamily': familyIndex,
      });
    }
  }

  void _showPersonalDataModal(BuildContext context) async {
  User? user = _auth.currentUser;

  if (user != null) {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    if (userSnapshot.exists) {
      _nameController.text = userSnapshot['firstName'] ?? '';
      _surnameController.text = userSnapshot['lastName'] ?? '';
      familyIdControllers[0].text = userSnapshot['familyId'] ?? '';
      _genderController.text = userSnapshot['gender'] ?? '';
      familyIdControllers[1].text = userSnapshot['familyId2'] ?? '';
      familyIdControllers[2].text = userSnapshot['familyId3'] ?? '';
      isCreator[0] = userSnapshot['isFamilyCreator1'] ?? false; 
      isCreator[1] = userSnapshot['isFamilyCreator2'] ?? false; 
      isCreator[2] = userSnapshot['isFamilyCreator3'] ?? false; 
      selectedFamily = userSnapshot['selectedFamily'];
      old1 = userSnapshot['familyId'] ?? '';
      old2 = userSnapshot['familyId2'] ?? '';
      old3 = userSnapshot['familyId3'] ?? '';
      _familyNameController.text = userSnapshot['family1Name'] ?? '';
      _family2NameController.text = userSnapshot['family2Name'] ?? '';
      _family3NameController.text = userSnapshot['family3Name'] ?? '';
    }
  }




  // ignore: use_build_context_synchronously
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void generateFamilyId(int index) {
            String uniqueId = Uuid().v4();
            familyIdControllers[index].text = uniqueId;
            isCreator[index] = true;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Изменение личных данных',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  
                  SizedBox(height: 8.0),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Имя'),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    controller: _surnameController,
                    decoration: InputDecoration(labelText: 'Фамилия'),
                  ),
                  SizedBox(height: 8.0),
                  Row(
  children: <Widget>[
    Text('Пол:'),
    Radio(
      value: 'Мужской',
      groupValue: _genderController.text,
      onChanged: (String? value) {
        setState(() {
          _genderController.text = value!;
        });
      },
    ),
    Text('Мужской'),
    Radio(
      value: 'Женский',
      groupValue: _genderController.text,
      onChanged: (String? value) {
        setState(() {
          _genderController.text = value!;
        });
      },
    ),
    Text('Женский'),
  ],
),
                  // SizedBox(height: 8.0),
                  Text(
  'Вы можете присоединиться к трем семьям, введя или сгенерировав код в соответствующих полях ниже',
  style: TextStyle(fontSize: 12.0, color: Colors.black54),
),
// SizedBox(height: 20.0),
                   TabBar(
  controller: _tabController,
  tabs: [
    for (int i = 0; i < familyIdControllers.length; i++)
      Tab(
        child: Text(
          'Код ${i + 1}',
          style: TextStyle(
            color: Color.fromARGB(255, 10, 114, 1),
          ),
        ),
      ),
  ],
),
SizedBox(height: 16.0),
SizedBox(
  height: 220,
  child: TabBarView(
    controller: _tabController,
    children: [
      for (int i = 0; i < familyIdControllers.length; i++)
        Column(
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: familyIdControllers[i],
                      onChanged: (value) {
                        setState(() {
                          isCreator[i] = false;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Код семьи ${i + 1}'),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: i == 0
                          ? _familyNameController
                          : i == 1
                              ? _family2NameController
                              : _family3NameController,
                      decoration: InputDecoration(labelText: 'Название Семьи ${i + 1}'),
                    ),
                    SizedBox(height: 10.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                      onPressed: () {
                        setState(() {
                          generateFamilyId(i);
                        });
                      },
                      child: Text('Сгенерировать код семьи ${i + 1}'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    ],
  ),
),

                  ElevatedButton(style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), 
  ),
                    onPressed: () async {
                      await _updatePersonalData(context);
                    },
                    child: Text('Сохранить'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

 Future<void> _showFamilySelectionModal(BuildContext context) async {
  User? user = _auth.currentUser;
  if (user != null) {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(user.uid).get();
    familyIdControllers[0].text = userSnapshot['familyId'] ?? '';
    familyIdControllers[1].text = userSnapshot['familyId2'] ?? '';
    familyIdControllers[2].text = userSnapshot['familyId3'] ?? '';
    selectedFamily = userSnapshot['selectedFamily'];
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<String> nonEmptyFamilyIds = [];
            List<String> familyNames = [];
            for (int i = 0; i < familyIdControllers.length; i++) {
              if (familyIdControllers[i].text.isNotEmpty) {
                nonEmptyFamilyIds.add(familyIdControllers[i].text);
                familyNames.add(
                  userSnapshot['family${i + 1}Name'] ?? 'Семья ${i + 1}',
                );
              }
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Выберите семью',
                      style:
                          TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    for (int i = 0; i < nonEmptyFamilyIds.length; i++)
                      ListTile(
                        title: Text(familyNames[i]),
                        onTap: () {
                          _changeSelectedFamily(i);
                          print('Selected family: ${familyNames[i]}');
                          Navigator.pop(context);
                        },
                        tileColor: i == selectedFamily - 1
                            ? Colors.green.withOpacity(0.3)
                            : null,
                      ),
                    SizedBox(height: 16.0),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}



     @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Код семьи',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            FutureBuilder<String?>(
              future: _getFamilyId(),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Image.asset('assets/loading.gif',
                        height: 200), );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                String trimmedFamilyId = snapshot.data!.length > 20
                    ? snapshot.data!.substring(0, 20) + '...' 
                    : snapshot.data!;

                return GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: snapshot.data!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Код семьи скопирован')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 10, 114, 1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, color: Colors.white, size: 32.0),
                        SizedBox(width: 16.0),
                        Text(
                          trimmedFamilyId,
                          style: TextStyle(color: Colors.white, fontSize: 18.0),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Text('Код семьи не найден');
              }
              
            },
          ),
          SizedBox(height: 20.0),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showFamilySelectionModal(context);
                },
               icon: Icon(Icons.group, size: 32.0),
                label: Text('Выбрать семью', style: TextStyle(fontSize: 18.0)),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 10, 114, 1),
                  padding: EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
           
            SizedBox(height: 8.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showPersonalDataModal(context);
                },
                icon: Icon(Icons.person, size: 32.0),
                label: Text('Личные данные', style: TextStyle(fontSize: 18.0)),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 10, 114, 1),
                  padding: EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          
          SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FavoriteMedicinesScreen()));
              },
              icon: Icon(Icons.favorite, size: 32.0),
              label: Text('Избранные лекарства', style: TextStyle(fontSize: 18.0)),
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 10, 114, 1),
                padding: EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyMedicinesScreen()));
              },
              icon: Icon(Icons.medical_services, size: 32.0),
              label: Text('Мои лекарства', style: TextStyle(fontSize: 18.0)),
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 10, 114, 1),
                padding: EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
          ),
          ),
        ],
      ),
    ));
  }
}

