import 'package:evaluacion_flutter/users_page.dart';
import 'package:flutter/material.dart';
import 'package:evaluacion_flutter/user_tasks_page.dart';


class UsersTabs extends StatefulWidget {
  const UsersTabs({super.key});

  @override
  State<StatefulWidget> createState() => _UsersTabsState();
}

class _UsersTabsState extends State<UsersTabs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    UsersPage(),
    UserTasksPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        selectedItemColor: Color.fromARGB(255, 22, 36, 62),

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Mis Tareas')
        ],
      ),
    );
  }
}