import 'dart:async';
import 'package:flutter/material.dart';

class TimerController extends ChangeNotifier {
  int _remainingTime = 0;
  Timer? _timer;

  int get remainingTime => _remainingTime;
  bool get isRunning => _timer != null;

  void start(int minutes) {
    _remainingTime = minutes * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        timer.cancel();
        _timer = null;
      } else {
        _remainingTime--;
        notifyListeners();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }
}
