import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusjoy/mind/config/navigation/app_routes_observer.dart';
import 'package:focusjoy/services/floating_focus_service.dart';
import 'package:focusjoy/widgets/global_focus_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('focusjoy/floating_focus');
  late Map<String, dynamic> native;
  final calls = <MethodCall>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppRoutesObserver.instance.showFocusShortcut.value = true;
    native = {
      'enabled': true,
      'permission': true,
      'running': true,
      'x': 1.0,
      'y': 0.5,
      'openFocusRequested': false,
    };
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getState':
              return native;
            case 'setEnabled':
              native['enabled'] = (call.arguments as Map)['enabled'];
              native['running'] =
                  native['enabled'] == true && native['permission'] == true;
              return native;
            case 'setPosition':
              native['x'] = (call.arguments as Map)['x'];
              native['y'] = (call.arguments as Map)['y'];
              return native;
            case 'consumeFocusRequest':
              final pending = native['openFocusRequested'];
              native['openFocusRequested'] = false;
              return pending;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    AppRoutesObserver.instance.showFocusShortcut.value = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'native overlay requires permission and a running enabled service',
    () async {
      final shortcut = FloatingFocusService(android: true);
      await shortcut.initialize();
      expect(shortcut.usesNativeOverlay, isTrue);
      native['running'] = false;
      await shortcut.refresh();
      expect(shortcut.usesNativeOverlay, isFalse);
      native['running'] = true;
      native['permission'] = false;
      await shortcut.refresh();
      expect(shortcut.usesNativeOverlay, isFalse);
      shortcut.dispose();
    },
  );

  test(
    'enabling requests overlay access only when Android has not granted it',
    () async {
      native['enabled'] = false;
      native['permission'] = false;
      native['running'] = false;
      final shortcut = FloatingFocusService(android: true);
      await shortcut.initialize();
      await shortcut.setEnabled(true);
      expect(calls.where((c) => c.method == 'requestPermission'), hasLength(1));
      native['permission'] = true;
      await shortcut.setEnabled(true);
      expect(shortcut.usesNativeOverlay, isTrue);
      expect(calls.where((c) => c.method == 'requestPermission'), hasLength(1));
      await shortcut.setEnabled(false);
      expect(shortcut.enabled, isFalse);
      expect(shortcut.usesNativeOverlay, isFalse);
      shortcut.dispose();
    },
  );

  test(
    'native drag position survives reopening and is clamped to valid fractions',
    () async {
      final first = FloatingFocusService(android: true);
      await first.initialize();
      await first.savePosition(0.24, 0.81);
      first.dispose();
      final reopened = FloatingFocusService(android: true);
      await reopened.initialize();
      expect(reopened.x, 0.24);
      expect(reopened.y, 0.81);
      await reopened.savePosition(-5, 9);
      expect(reopened.x, 0);
      expect(reopened.y, 1);
      reopened.previewPosition(double.nan, double.infinity);
      expect(reopened.x, 0);
      expect(reopened.y, 1);
      reopened.dispose();
    },
  );

  test('desktop position and enabled preference survive reopening', () async {
    final first = FloatingFocusService(android: false);
    await first.initialize();
    await first.savePosition(0.33, 0.72);
    await first.setEnabled(false);
    first.dispose();
    final reopened = FloatingFocusService(android: false);
    await reopened.initialize();
    expect(reopened.enabled, isFalse);
    expect(reopened.x, 0.33);
    expect(reopened.y, 0.72);
    reopened.dispose();
  });

  test('cold-start and warm Focus requests are consumed once', () async {
    native['openFocusRequested'] = true;
    final shortcut = FloatingFocusService(android: true);
    await shortcut.initialize();
    expect(shortcut.pendingOpenFocus, isTrue);
    await shortcut.consumeFocusRequest();
    await shortcut.refresh();
    expect(shortcut.pendingOpenFocus, isFalse);
    native['openFocusRequested'] = true;
    await shortcut.refresh();
    expect(shortcut.pendingOpenFocus, isTrue);
    await shortcut.consumeFocusRequest();
    expect(shortcut.pendingOpenFocus, isFalse);
    expect(calls.where((c) => c.method == 'consumeFocusRequest'), hasLength(2));
    shortcut.dispose();
  });

  test('game and splash visibility is sent to the native overlay', () async {
    final shortcut = FloatingFocusService(android: true);
    await shortcut.initialize();
    await shortcut.setInAppVisible(false);
    await shortcut.setInAppVisible(true);
    expect(
      calls.where((c) => c.method == 'setInAppVisible').map((c) => c.arguments),
      [false, true],
    );
    shortcut.dispose();
  });

  test(
    'missing native integration reports a retry message without crashing gestures',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final shortcut = FloatingFocusService(android: true);
      await shortcut.initialize();
      await shortcut.savePosition(0.4, 0.6);
      expect(shortcut.x, 0.4);
      expect(shortcut.error, contains('Restart FocusJoy'));
      shortcut.dispose();
    },
  );

  Widget app(FloatingFocusService shortcut) => ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('Dashboard')),
            GlobalFocusButton(shortcut: shortcut),
          ],
        ),
      ),
    ),
  );
  final button = find.byKey(const ValueKey('floating-focus-button'));

  testWidgets(
    'drag moves the fallback freely and saves its released position',
    (tester) async {
      final shortcut = FloatingFocusService(android: false);
      await shortcut.initialize();
      await tester.pumpWidget(app(shortcut));
      final start = tester.getRect(button);
      await tester.drag(button, const Offset(-250, 90));
      await tester.pumpAndSettle();
      final moved = tester.getRect(button);
      expect(moved.left, lessThan(start.left - 150));
      expect(moved.top, greaterThan(start.top + 40));
      final reopened = FloatingFocusService(android: false);
      await reopened.initialize();
      expect(reopened.x, shortcut.x);
      expect(reopened.y, shortcut.y);
      await tester.pumpWidget(const SizedBox());
      shortcut.dispose();
      reopened.dispose();
    },
  );

  testWidgets(
    'drag stays within the screen and keeps its position after a resize',
    (tester) async {
      final shortcut = FloatingFocusService(android: false);
      await shortcut.initialize();
      await tester.pumpWidget(app(shortcut));
      await tester.drag(button, const Offset(-4000, -4000));
      await tester.pumpAndSettle();
      expect(tester.getRect(button).left, greaterThanOrEqualTo(8));
      expect(tester.getRect(button).top, greaterThanOrEqualTo(8));
      await shortcut.savePosition(1, 1);
      await tester.binding.setSurfaceSize(const Size(320, 480));
      await tester.pumpAndSettle();
      final rect = tester.getRect(button);
      expect(rect.right, lessThanOrEqualTo(312));
      expect(rect.bottom, lessThanOrEqualTo(472));
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
      shortcut.dispose();
    },
  );

  testWidgets('Flutter does not duplicate the running Android overlay', (
    tester,
  ) async {
    final shortcut = FloatingFocusService(android: true);
    await shortcut.initialize();
    await tester.pumpWidget(app(shortcut));
    expect(find.text('Focus'), findsNothing);
    native['running'] = false;
    await shortcut.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Focus'), findsOneWidget);
    await shortcut.setEnabled(false);
    await tester.pumpAndSettle();
    expect(find.text('Focus'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    shortcut.dispose();
  });

  testWidgets('the in-app button respects the game visibility rule', (
    tester,
  ) async {
    final shortcut = FloatingFocusService(android: false);
    await shortcut.initialize();
    await tester.pumpWidget(app(shortcut));
    expect(find.text('Focus'), findsOneWidget);
    AppRoutesObserver.instance.showFocusShortcut.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Focus'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    shortcut.dispose();
  });
}
