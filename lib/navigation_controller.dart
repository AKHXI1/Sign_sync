import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/about_page.dart'; // Import the new AboutPage
// Import your existing screens and the new AboutPage
import 'screens/sign_to_text_screen.dart';
import 'screens/text_to_sign_screen.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({Key? key}) : super(key: key);

  @override
  _NavigationControllerState createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  // 0 = TextToSignScreen, 1 = SignToTextScreen
  int _selectedIndex = 0;

  final List<_NavItem> _items = [
    _NavItem(
      widget: const TextToSignScreen(),
      label: 'Text to Sign',
      icon: Icons.text_fields,
    ),
    _NavItem(
      widget: SignToTextScreen(),
      label: 'Sign to Text',
      icon: Icons.sign_language,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5E6C8), // Pastel beige/golden background

      // Add Drawer here
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF8B6F47), // Dark brown-golden
              ),
              child: Center(
                child: Text(
                  'SIGN-SYNC',
                  style: GoogleFonts.dmSerifText(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Drawer Items
            ListTile(
              leading: const Icon(Icons.text_fields, color: Color(0xFF8B6F47)),
              title: const Text('Text to Sign'),
              onTap: () {
                // Navigate to the "Text to Sign" screen
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.sign_language, color: Color(0xFF8B6F47)),
              title: const Text('Sign to Text'),
              onTap: () {
                // Navigate to the "Sign to Text" screen
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            const Divider(),

            // About Item
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF8B6F47)),
              title: const Text('About'),
              onTap: () {
                // Navigate to the About page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: Text(
          "Sign-Sync",
          style: GoogleFonts.dmSerifText(
            // fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF8B6F47), // Dark brown-golden
      ),

      // Show the selected screen
      body: _items[_selectedIndex].widget,

      // Bottom Navbar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF8B6F47),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _items.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// Helper class for navigation items
class _NavItem {
  final Widget widget;
  final String label;
  final IconData icon;

  const _NavItem({
    required this.widget,
    required this.label,
    required this.icon,
  });
}
