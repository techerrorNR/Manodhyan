import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'home_screen.dart';
import 'todo_screen.dart';
import 'challenge_screen.dart';
import 'score_screen.dart';
import 'create_task_modal.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const TodoScreen(),
    const HomeScreen(),
    const SizedBox(), // FAB handler
    const ChallengeScreen(),
    const ScoreScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      showCreateTaskModal(context);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D21),
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1B192F),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.listTodo, color: Colors.white),
              onPressed: () => _onTabTapped(0),
            ),
            IconButton(
              icon: const Icon(LucideIcons.target, color: Colors.white),
              onPressed: () => _onTabTapped(1),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(LucideIcons.diamond, color: Colors.white),
              onPressed: () => _onTabTapped(3),
            ),
            IconButton(
              icon: const Icon(LucideIcons.calendarDays, color: Colors.white),
              onPressed: () => _onTabTapped(4),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: () => _onTabTapped(2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
