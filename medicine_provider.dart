import 'package:flutter/material.dart';
import 'medicine_service.dart';
import 'medicine.dart';

class MedicineProvider with ChangeNotifier {
  final MedicineService _medicineService = MedicineService();
  List<Medicine> _medicines = [];

  List<Medicine> get medicines => _medicines;

  MedicineProvider() {
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    _medicines = await _medicineService.fetchMedicines();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _medicineService.addMedicine(medicine);
    _medicines.add(medicine);
    notifyListeners();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _medicineService.updateMedicine(medicine);
    int index = _medicines.indexWhere((med) => med.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;
      notifyListeners();
    }
  }

  Future<void> deleteMedicine(String id) async {
    await _medicineService.deleteMedicine(id);
    _medicines.removeWhere((med) => med.id == id);
    notifyListeners();
  }
}
