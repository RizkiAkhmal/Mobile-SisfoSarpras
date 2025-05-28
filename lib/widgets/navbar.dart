import 'package:flutter/material.dart';
import 'package:fe_sisfo_sarpas/pages/home.dart';
import 'package:fe_sisfo_sarpas/pages/peminjaman.dart';
import 'package:fe_sisfo_sarpas/pages/history.dart';
import 'package:fe_sisfo_sarpas/pages/profile.dart';
import 'package:fe_sisfo_sarpas/pages/pengembalian.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Peminjaman',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    PeminjamanForm(),
    PeminjamanHistoryPage(),
    PengembalianForm(),
    ProfilePage(),
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
      bottomNavigationBar: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black54,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Pinjam',
              ),
              BottomNavigationBarItem(
                icon: SizedBox.shrink(), // kosong karena diganti custom
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_return),
                label: 'Kembali',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Akun',
              ),
            ],
          ),
          Positioned(
            top: -25, // Reduced from -30 to -25 to make it smaller
            child: GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.access_time,
                      size: 24, // Reduced from 30 to 24
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Riwayat',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedIndex == 2 ? Colors.black : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
