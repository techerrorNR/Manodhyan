import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/timer_controller.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            'Select Focus Time',
            style: TextStyle(color: Colors.white, fontSize: 20),
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
        ],
      ),
    );
  }
}
