
import 'package:flutter/material.dart';
import 'package:testiks/profile.dart';
import 'package:testiks/settings.dart';
import 'family.dart';
import 'drugs_list_screen.dart';
import 'map.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _currentIndex = 0;

  final List<Widget> _pages = [
    MedicineListPage(),
    const LocationAccess(),
    FamilyPage(),
    ProfilePage(),
    SettingsPage(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Семейная аптечка'), 
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 10, 114, 1),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
     
        items: [
          BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 10, 114, 1),
            icon: Icon(Icons.list),
            label: 'Лекарства',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 10, 114, 1),
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 10, 114, 1),
            icon: Icon(Icons.people),
            label: 'Семья',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 10, 114, 1),
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 10, 114, 1),
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
