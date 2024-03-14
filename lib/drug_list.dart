import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'medicine_provider.dart';
import 'create_med.dart';
import 'drug_card.dart';

class MedicineList extends StatefulWidget {
  static const routeName = '/list';

  @override
  State<MedicineList> createState() => MedicineListState();

  static MedicineListState? of(BuildContext context) {
    return context.findAncestorStateOfType<MedicineListState>();
  }
}

class MedicineListState extends State<MedicineList> {
  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  QuerySnapshot? familyMedicines;

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final messaging = FirebaseMessaging.instance;


  int levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> costs = List<int>.filled(b.length + 1, 0);

    for (var j = 0; j <= b.length; j++) {
      costs[j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      int lastValue = i;
      for (var j = 1; j <= b.length; j++) {
        int newValue = costs[j - 1];
        if (a[i - 1] != b[j - 1]) {
          newValue = newValue < lastValue ? newValue : lastValue;
          newValue = newValue < costs[j] ? newValue : costs[j];
          newValue += 1;
        }
        costs[j - 1] = lastValue;
        lastValue = newValue;
      }
      costs[b.length] = lastValue;
    }

    return costs[b.length];
  }

  void _navigateToCreateMedicineScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMedicinePage(),
      ),
    ).then((_) {
      _fetchMedicines();
    });
  }

  void func() async {
    print("ЖЖЖЖЖ");
    _fetchMedicines();
  }

  void _fetchMedicines() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String familyId = await _getFamilyId();

      if (familyId.isNotEmpty) {
        familyMedicines = await _firestore
            .collection('drugs')
             .where(Filter.or(
              Filter.and(
              Filter('familyId', isEqualTo: familyId),
              Filter('isPrivate', isEqualTo: false),),
              Filter.and(
              Filter('familyId', isEqualTo: familyId),
              Filter('isPrivate', isEqualTo: true),
              Filter('addedBy', isEqualTo: user.uid),
            )
            ))
            .get();

        setState(() {
          medicines = familyMedicines!.docs
              .map((DocumentSnapshot doc) => doc.data() as Map<String, dynamic>)
              .toList();
          filteredMedicines = List.from(medicines);
        });
      }
    }
    // sendLowQuantityNotification(filteredMedicines.first.);
  }

  List<DropdownMenuItem<String>> _buildAddressDropdownItems() {
    Set<String> allAddresses = medicines
        .map<String>((medicine) => medicine['address'].toString())
        .toSet();

    List<DropdownMenuItem<String>> items = allAddresses
        .map<DropdownMenuItem<String>>((address) => DropdownMenuItem<String>(
              value: address,
              child: Text(
                address,
                style: TextStyle(
                  color: Color.fromARGB(255, 10, 114, 1),
                  fontWeight: FontWeight.bold, // Make the text bold
                ),
              ),
            ))
        .toList();

    if (allAddresses.contains('Выберите адрес')) {
    items.removeWhere((item) => item.value == 'Выберите адрес');
  }

    items.insert(
      0,
      DropdownMenuItem<String>(
        value: 'All Addresses',
        child: Text(
          'Все адреса',
          style: TextStyle(
            color: Color.fromARGB(255, 10, 114, 1),
            fontWeight: FontWeight.bold, 
          ),
        ),
      ),
    );

    return items;
  }

  void _filterByAddress(String selectedAddress) {
    setState(() {
      if (selectedAddress == 'All Addresses') {
        filteredMedicines = List.from(medicines);
      } else {
        filteredMedicines = medicines
            .where((medicine) => medicine['address'] == selectedAddress)
            .toList();
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredMedicines = List.from(medicines);
      });
      return;
    }
    query = query.toLowerCase();
    setState(() {
      filteredMedicines = medicines.where((medicine) {
        String medicineName = medicine['name'].toString().toLowerCase();
        String medicineComment = medicine['comment'].toString().toLowerCase();

        return levenshteinDistance(query, medicineName) <= 2 ||
            medicineName.startsWith(query) ||
            levenshteinDistance(query, medicineComment) <= 2 ||
            medicineComment.startsWith(query);
      }).toList();
    });
  }

  String selectedAddress = 'All Addresses';

  @override
Widget build(BuildContext context) {
  return Consumer<MedicineProvider>(
    builder: (context, counterProvider, child) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Поиск по названиям и комментариям',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedAddress,
              onChanged: (String? newValue) {
                setState(() {
                  selectedAddress = newValue!;
                  _filterByAddress(newValue);
                });
              },
              items: _buildAddressDropdownItems(),
              isExpanded: true,
              hint: Text('Filter by Address'),
            ),
          ),
           filteredMedicines.isEmpty
              ? Container(
                  margin: EdgeInsets.all(8.0),
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'У вас нет лекарств. Вы можете добавить их, нажав на знак +.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              :  
              Expanded(
            child: ListView.builder(
              itemCount: filteredMedicines.length,
              itemBuilder: (context, index) {
                var medicine = filteredMedicines[index];
                var id = familyMedicines?.docs[index].id;
                var name = medicine['name'];
                var expiryDate = medicine['expiryDate'];
                var quantity = medicine['quantity'];
                var storageOptions = medicine['storageOptions'];
                var address = medicine['address'];
                var imageUrl = medicine['imageUrl'];
                var comment = medicine['comment'];
                var isFavorite = medicine['isFavorite'];
                var isPrivate = medicine['isPrivate'];
                var likedBy = medicine['likedBy'];
                var notificationDays = medicine['notificationDays'];
                var quantityNum = medicine['quantityNum'];
                var addedBy = medicine['addedBy'];

                return MedicineCard(
                  key: Key(
                      '${medicine}'),
                  expiryDate: expiryDate,
                  name: name,
                  medicine: id,
                  notificationDays: notificationDays,
                  comment: comment,
                  quantity: quantity,
                  storageOptions: storageOptions,
                  address: address,
                  imageUrl: imageUrl,
                  isFavorite: isFavorite,
                  isPrivate: isPrivate,
                  
                  onSwiped: (String id, bool isSwipeRight) async {
                    if (!isSwipeRight) {
                      await _firestore.collection('drugs').doc(id).delete();
                      _fetchMedicines();
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateMedicinePage(
                              name: name,
                              expiryDate: expiryDate,
                              comment: comment,
                              quantity: quantity,
                              storageOptions: storageOptions,
                              address: address,
                              imageUrl: imageUrl,
                              notificationDays: notificationDays,
                              medicineId: id,
                              isEditing: true,
                              isFavorite: isFavorite,
                              isPrivate: isPrivate,
                              quantityNum: quantityNum,
                              likedBy: likedBy,
                              addedBy: addedBy,

                            ),
                          ));
                    }
                  },
                );
              },
            ),
          ),
          Container(
            child: Container(
              child: FloatingActionButton(
                backgroundColor: Color.fromARGB(255, 10, 114, 1),
                onPressed: _navigateToCreateMedicineScreen,
                child: Icon(Icons.add),
                mini: true,
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<String> _getFamilyId() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (userSnapshot.exists) {
        if (userSnapshot['selectedFamily'] == 1) {
          return userSnapshot['familyId'];
        } else if (userSnapshot['selectedFamily'] == 2) {
          return userSnapshot['familyId2'];
        } else {
          return userSnapshot['familyId3'];
        }
      }
    }

    return ''; 
  }
}
