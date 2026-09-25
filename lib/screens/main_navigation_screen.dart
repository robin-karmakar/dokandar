import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_bar_item.dart';
import 'dashboard_tab_wrapper.dart';
import 'products_tab.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'new_sale_screen.dart';

// The main app shell shown after login: bottom navigation with 4 tabs
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      DashboardTabWrapper(),
      ProductsTab(),
      const HistoryScreen(),
      ProfileScreen(key: UniqueKey()),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
     // Refresh profile data when returning to the tab.
      if (index == 3) {
        _tabs[3] = ProfileScreen(key: UniqueKey());
      }
      _currentIndex = index;
    });
  }

  void _openNewSale() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewSaleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButton: isKeyboardOpen
          ? null
          : FloatingActionButton.extended(
              onPressed: _openNewSale,
              backgroundColor: AppColors.accent,
              elevation: 3,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 14),
              icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
              label: const Text(
                'New Sale',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavBarItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _onNavTap(0),
              ),
              NavBarItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Products',
                isActive: _currentIndex == 1,
                onTap: () => _onNavTap(1),
              ),
              const SizedBox(width: 65),
              NavBarItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'History',
                isActive: _currentIndex == 2,
                onTap: () => _onNavTap(2),
              ),
              NavBarItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: _currentIndex == 3,
                onTap: () => _onNavTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}