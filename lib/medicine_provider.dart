import 'package:flutter/material.dart';

class MedicineProvider extends ChangeNotifier {
  String? _swipedMedicineId;
  bool? _isSwipeRight;
  String? get swipedMedicineId => _swipedMedicineId;
  bool? get isSwipeRight => _isSwipeRight;

  void setSwipeDetails(String id, bool isSwipeRight) {
    _swipedMedicineId = id;
    _isSwipeRight = isSwipeRight;
    notifyListeners();
  }

  void clearSwipeDetails() {
    _swipedMedicineId = null;
    _isSwipeRight = null;
    notifyListeners();
  }
  void refreshMedicines() {
    notifyListeners();
  }
}
