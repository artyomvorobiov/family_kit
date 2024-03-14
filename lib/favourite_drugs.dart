import 'package:flutter/material.dart';

import 'fav_drug_list.dart';

class FavoriteMedicinesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        title: Text('Избранные лекарства'),
      ),
      body: MedicineFavList(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}