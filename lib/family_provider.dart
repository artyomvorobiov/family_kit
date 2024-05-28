import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedFamilyId;
  String? get selectedFamilyId => _selectedFamilyId;

  FamilyProvider() {
    _loadFamilyId();
  }

  Future<void> _loadFamilyId() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (userSnapshot.exists) {
        _selectedFamilyId = userSnapshot['selectedFamily'] == 1
            ? userSnapshot['familyId']
            : userSnapshot['selectedFamily'] == 2
                ? userSnapshot['familyId2']
                : userSnapshot['familyId3'];
        notifyListeners();
      }
    }
  }

  Future<void> updateFamilyId(String newFamilyId) async {
    _selectedFamilyId = newFamilyId;
    notifyListeners();
  }
}
