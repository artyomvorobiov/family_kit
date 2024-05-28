import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'medicine.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Medicine>> fetchMedicines() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .get();
      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    }
    return [];
  }

  Future<void> addMedicine(Medicine medicine) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .add(medicine.toFirestore());
      medicine.id = docRef.id;
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(medicine.id)
          .update(medicine.toFirestore());
    }
  }

  Future<void> deleteMedicine(String id) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(id)
          .delete();
    }
  }
}
