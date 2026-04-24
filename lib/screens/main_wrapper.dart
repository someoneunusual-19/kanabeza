// lib/screens/main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:kanabeza/models/app_user.dart';
import 'package:kanabeza/screens/manager/sales_history.dart';
import 'package:kanabeza/widgets/entry_botom_sheet.dart';

import 'dashboard_screen.dart';
import 'manager/reports_screen.dart';

class MainWrapper extends StatefulWidget {
  final AppUser user;
  const MainWrapper({super.key, required this.user});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isManager = widget.user.role == UserRole.manager;

    // The pages available depend on the role
    final List<Widget> pages = [
      DashboardScreen(user: widget.user),
      isManager ? const ReportsScreen() : const SalesHistoryScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allows content to flow behind the BottomAppBar
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      
      // The "Action" button - opens the correct entry sheet
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => EntryBottomSheet.show(context, widget.user),
        backgroundColor: Colors.indigoAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: const Color(0xFF18181B), // Shadcn-style dark surface
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 1: Dashboard
            IconButton(
              icon: Icon(
                Icons.grid_view_rounded, 
                color: _currentIndex == 0 ? Colors.indigoAccent : Colors.grey
              ),
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            const SizedBox(width: 40), // Gap for the Floating Action Button
            // Tab 2: Analytics or Sales History
            IconButton(
              icon: Icon(
                isManager ? Icons.analytics_outlined : Icons.history_rounded,
                color: _currentIndex == 1 ? Colors.indigoAccent : Colors.grey,
              ),
              onPressed: () => setState(() => _currentIndex = 1),
            ),
          ],
        ),
      ),
    );
  }
}