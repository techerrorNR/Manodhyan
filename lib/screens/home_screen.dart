import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/timer_controller.dart';
import '../routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTime = 20;

  void _increaseTime() {
    if (!Provider.of<TimerController>(context, listen: false).isRunning) {
      setState(() {
        if (selectedTime < 120) selectedTime += 5;
      });
    }
  }

  void _decreaseTime() {
    if (!Provider.of<TimerController>(context, listen: false).isRunning) {
      setState(() {
        if (selectedTime > 5) selectedTime -= 5;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = Provider.of<TimerController>(context);
    final remaining = timer.remainingTime;
    final percent = selectedTime == 0
        ? 0
        : (remaining / (selectedTime * 60)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            'Select Focus Time',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                icon: Icons.local_fire_department,
                value: '${timer.streak}',
                label: 'Streak',
                color: Colors.orange,
              ),
              const SizedBox(width: 24),
              _StatBadge(
                icon: Icons.diamond,
                value: '${timer.crystals}',
                label: 'Crystals',
                color: Colors.cyanAccent,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: timer.isRunning ? percent .toDouble(): 1.0,
                  strokeWidth: 10,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.orange),
                  backgroundColor:
                      Colors.deepPurple.withValues(alpha: 0.3),
                ),
              ),
              ClipOval(
                child: Image.asset(
                  'assets/crystals/amber.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            timer.isRunning
                ? '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}'
                : '${selectedTime.toString().padLeft(2, '0')}:00',
            style: const TextStyle(color: Colors.white, fontSize: 26),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decreaseTime,
                icon: const Icon(Icons.remove_circle, color: Colors.white),
                iconSize: 36,
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _increaseTime,
                icon: const Icon(Icons.add_circle, color: Colors.white),
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (timer.isRunning) {
                await timer.cancelSession();
              } else {
                await timer.startSession(selectedTime);
              }
            },
            child: Text(
              timer.isRunning ? "Stop" : "Start Focusing",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: const Color(0xFF1B192F),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock Device Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Grant permissions to use ManoDhyan’s blocking features '
                    'without leaving ManoDhyan.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.ManoDhyanPermissions);
                      },
                      icon: const Icon(Icons.shield_moon_outlined),
                      label: const Text(
                        'Open ManoDhyan Permissions',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1B192F),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ManoDhyan Control Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open the blocking dashboard, restriction groups, bedtime '
                    'routine, and more.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.ManoDhyanFeatureHub);
                      },
                      child: const Text('Open ManoDhyan Controls'),
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
class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}
