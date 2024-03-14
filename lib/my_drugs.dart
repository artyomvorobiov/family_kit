import 'package:flutter/material.dart';

import 'my_drugs_list_screen.dart';

class MyMedicinesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        title: Text('Мои лекарства'),
      ),
      body: MyMedicineList(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}