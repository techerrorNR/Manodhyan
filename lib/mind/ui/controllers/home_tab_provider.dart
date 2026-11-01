import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the home bar and shortcuts in sync without pushing another home page.
final homeTabProvider = StateProvider<int>((ref) => 0);
