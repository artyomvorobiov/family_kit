import 'package:flutter/material.dart';

import 'drug_list.dart';

class MedicineListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MedicineList(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}