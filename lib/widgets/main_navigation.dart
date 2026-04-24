// // lib/widgets/main_navigation.dart
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:kanabeza/manager/excel_bulk_entry.dart';
// import 'package:kanabeza/models/app_user.dart';

// class MainNavigation extends StatefulWidget {
//   final UserRole role;
//   const MainNavigation({super.key, required this.role});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> {
//   int _selectedIndex = 0;

//   List<Widget> get _screens => widget.role == UserRole.manager 
//     ? [const Dashboard(), const ExcelBulkEntry(), const Settings()] 
//     : [const POSScanner(), const SalesHistory(), const Profile()];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true, // Allows background to show through blurred bar
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: Container(
//         margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
//         height: 70,
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.8),
//           borderRadius: BorderRadius.circular(25),
//           border: Border.all(color: Colors.white10),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(25),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: BottomNavigationBar(
//               currentIndex: _selectedIndex,
//               onTap: (i) => setState(() => _selectedIndex = i),
//               backgroundColor: Colors.transparent,
//               selectedItemColor: Colors.indigoAccent,
//               unselectedItemColor: Colors.grey,
//               showSelectedLabels: false,
//               showUnselectedLabels: false,
//               type: BottomNavigationBarType.fixed,
//               items: _buildNavItems(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   List<BottomNavigationBarItem> _buildNavItems() {
//     if (widget.role == UserRole.manager) {
//       return const [
//         BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Stats'),
//         BottomNavigationBarItem(icon: Icon(Icons.grid_on_rounded), label: 'Inventory'),
//         BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
//       ];
//     }
//     return const [
//       BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
//       BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Sales'),
//       BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
//     ];
//   }
// }