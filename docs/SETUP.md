# FocusJoy developer setup

This guide covers a fresh checkout, Android setup, development checks, and the parts of the app that need device testing. Start at the [README](../README.md) for the overview and [CONTRIBUTING.md](../CONTRIBUTING.md) for the pull request workflow.

## 1. Requirements

| Tool | Project reference |
| --- | --- |
| Git | Available in your terminal |
| Flutter | Current development installation: **3.41.4 stable**, bundled Dart **3.11.1**; not pinned by a version-manager file |
| Dart constraints | `pubspec.yaml`: `^3.7.2`; committed lockfile: Dart `>=3.9.0-0 <4.0.0` and Flutter `>=3.32.0`. The lower manifest constraint alone is insufficient for the locked dependencies. |
| Java | **JDK 17**; Android Java/Kotlin source targets are 17 |
| Android platform | **Android SDK Platform 36** (`compileSdk = 36`) |
| Android tools | SDK Build-Tools, Platform-Tools, Command-line Tools; emulator if needed |
| Editor | Android Studio, or VS Code with Dart and Flutter extensions |
| Device | Physical Android phone recommended for alarms, overlays, usage tracking, and restrictions |

The checked-in Android toolchain uses **AGP 8.7.0**, **Kotlin 2.1.20**, and **Gradle 8.10.2**. Use the included Gradle wrapper rather than installing a separate Gradle version. `minSdk` and `targetSdk` currently come from Flutter; `compileSdk` is explicitly 36. The icon generator's `min_sdk_android` is not the application's minimum SDK setting.

Platform folders for iOS, macOS, Windows, Linux, and web exist, but the app relies on Android-specific method channels and services. Their presence does not establish feature parity. Use Android for end-to-end contributions; cross-platform support needs a separate compatibility review. Building for iOS requires macOS and Xcode.

Official references: [Flutter installation](https://docs.flutter.dev/install), [SDK archive](https://docs.flutter.dev/install/archive), and [Android setup](https://docs.flutter.dev/platform-integration/android/setup).

## 2. Install and verify the tools

Install Flutter and add its `bin` directory to `PATH`. Flutter supplies Dart; a separate Dart installation is unnecessary. For a reproducible starting point, use the reference Flutter version above rather than automatically upgrading the project and dependencies together.

In Android Studio, open **SDK Manager** and install Platform 36 and the SDK tools listed above. Install native tools such as NDK/CMake if Flutter or a dependency requests them; this app does not explicitly pin an NDK version.

```sh
flutter --version
java -version
flutter doctor -v
flutter doctor --android-licenses
```

Review and accept the Android SDK licenses, then resolve Android-toolchain errors reported by `flutter doctor`. Warnings for unused platforms do not prevent Android development. `flutter doctor -v` shows which Java installation Flutter actually uses; it may differ from Java on your shell's `PATH`.

If Flutter cannot locate your SDK or JDK, configure your own absolute paths:

```sh
flutter config --android-sdk "PATH_TO_YOUR_ANDROID_SDK"
flutter config --jdk-dir "PATH_TO_YOUR_JDK_17"
```

These settings affect your local Flutter installation. Do not copy the original maintainer's Windows paths into source files.

## 3. Fork, clone, and restore dependencies

Fork [techerrorNR/Manodhyan](https://github.com/techerrorNR/Manodhyan) on GitHub. Replace `YOUR_GITHUB_USERNAME` below:

```sh
git clone https://github.com/YOUR_GITHUB_USERNAME/Manodhyan.git
cd Manodhyan
git remote add upstream https://github.com/techerrorNR/Manodhyan.git
flutter pub get
```

Keep the committed `pubspec.lock` for this application. Do not run a broad dependency upgrade just to set up a checkout. Downloads require internet access on the first run; Gradle also fetches Android dependencies on the first build.

There is no required `.env`, Firebase configuration, backend, API key, or production signing key for local debug development.

Flutter normally creates or updates the ignored `android/local.properties` file. If Gradle reports missing `flutter.sdk` or `sdk.dir`, run the Flutter commands from the repository root and verify this file. If manual repair is needed, use your own paths. A Windows example is:

```properties
sdk.dir=C:/Users/YOUR_WINDOWS_USER/AppData/Local/Android/Sdk
flutter.sdk=C:/src/flutter
```

Forward slashes avoid escaping backslashes in Java properties files. Never commit this machine-specific file.

## 4. Connect Android and launch

On a phone, enable Developer options and USB debugging, connect a data-capable USB cable, and approve the computer's debugging prompt. Windows may need the manufacturer's USB driver. Alternatively, start an emulator in Android Studio's Device Manager.

```sh
adb devices -l
flutter devices
```

The Android device must appear as `device`, not `offline` or `unauthorized`. If `adb` is not on `PATH`, use the executable in your SDK's `platform-tools` directory.

```sh
flutter run -d YOUR_ANDROID_DEVICE_ID -t lib/main.dart
```

Use **`lib/main.dart`**. The older `lib/mind/main.dart` entry point belongs to the inherited foundation and is not the unified FocusJoy launch path. The Dart package is `focusjoy`; the Android application ID and namespace are `com.sjtechnovation.focusjoy`.

Hot reload is useful for Dart UI changes. After editing Kotlin, the manifest, native permissions, plugin registration, or Android services, stop the running app and launch it again to rebuild/install the native changes.

## 5. Grant permissions for the features you test

Use the in-app permission flow or **Tools → Device permissions**. Settings labels vary by OS and manufacturer. Grant access for the feature being tested and check denial/revocation handling too.

| Access | What to verify |
| --- | --- |
| Usage access | Activity statistics, tracking, and restriction decisions |
| Display over other apps | Focus shortcut and restriction overlays |
| Notifications | Alarm and foreground-service notifications |
| Alarms & reminders | Exact scheduling for Planner alarms and relevant timers |
| Accessibility | Restriction features using the accessibility service |
| Notification access | Notification history and controls |
| Do Not Disturb access | Features changing notification policy |
| VPN consent | Local VPN website/network restriction features |
| Device admin / battery settings | Optional protection features and device-specific background behavior |

For alarms, enable exact alarm access when requested, allow notifications, and check full-screen notification access if offered by Android. An alarm schedules work inside FocusJoy; it is not expected to create an entry in the manufacturer's Clock app.

For the floating button, use **Tools → Floating Focus button** controls, allow overlay access, then return to FocusJoy so the service can start. Drag the pill and test it after returning Home and swiping the app away from recents. Android force-stop/Stop app controls stop the service; these differ from normal backgrounding. OEM power management can impose additional limits.

## 6. Analyze and test

From the repository root:

```sh
flutter analyze
flutter test --no-pub test/focus_reward_test.dart test/notes_controller_test.dart test/mental_math_test.dart test/alarm_scheduling_test.dart test/floating_focus_test.dart
```

Run `flutter pub get` first; `--no-pub` reuses restored dependencies. The targeted suite had **52 passing tests** at the alarm/overlay implementation checkpoint; rerun it for your checkout rather than treating that number as a CI guarantee.

`test/widget_test.dart` is an outdated starter counter test. A plain `flutter test` includes it and is not the established regression command. Updating it requires initializing/mocking the app's providers and platform dependencies; do not merely change the expected counter text.

There may be pre-existing repository-wide analysis findings. Include relevant output in your PR and distinguish new findings from existing ones. Do not disable lint rules across the project to hide a local issue.

Format only the Dart files you changed:

```sh
dart format lib/path/to/changed_file.dart test/path/to/changed_test.dart
git diff --check
```

### Manual checks on a phone

- Start, finish, cancel, and reopen a focus session; confirm rewards are awarded once and cancelled sessions earn nothing.
- Create/edit/toggle/delete alarms, schedule multiple alarms, and test a daily repeat. Try denied permission, a locked screen, and returning from Android Settings.
- Move the floating button, reopen the app, rotate the device, and open Focus from another app. Confirm a single shortcut and the existing Focus tab appear.
- Save/edit/delete notes and tasks, then relaunch to check persistence.
- Run Mental Maths at different levels, inspect results/history, and check the daily allowance and background/resume behavior.
- For restriction or tracking changes, test granted and revoked access on a real device and record OS/manufacturer details.

Host tests do not validate native service lifecycle, actual alarm delivery, or OEM background behavior.

## Architecture and generated code

The app combines the inherited wellbeing stack in `lib/mind/` with newer FocusJoy controllers, screens, and services in top-level `lib/` folders. Existing `ManoDhyan` names remain in some classes. Follow the surrounding module rather than renaming unrelated code in a feature PR.

- **State:** Provider/ChangeNotifier for several newer controllers; Riverpod for the wellbeing foundation and navigation state.
- **Persistence:** Drift/SQLite for wellbeing records; SharedPreferences/JSON for planner, notes, game settings/history, and scheduling metadata. Native services also use preferences. Do not assume a database-only export contains every newer feature's data.
- **Android bridge:** `lib/mind/core/services/method_channel_service.dart` and `MainActivity.kt` connect wellbeing features. The shortcut uses the separate `focusjoy/floating_focus` channel in `lib/services/floating_focus_service.dart`.
- **Background work:** Alarm delivery can run in another isolate; preserve entry-point annotations, reload behavior, and scheduling/error handling. Lifecycle and persistence changes need regression checks.
- **Translations:** Sources are in `lib/mind/l10n/*.arb`, with generated Dart in `lib/mind/l10n/generated/`. Check generation configuration before regenerating; do not hand-edit generated translations or assume every newer screen is already localized.
- **Colors:** Shared palette definitions are in `lib/mind/config/app_palette.dart`.

After editing Drift declarations, regenerate from the root:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Review and commit relevant generated changes. Schema changes need a migration plan for existing data; do not edit generated `.g.dart` files by hand.

## Branding assets

The master logo is `assets/logo/focusjoy.svg`. Generated assets are committed, so ordinary app development does not require Python. For intentional logo changes:

```sh
python -m venv .venv
```

Activate using `.venv\Scripts\Activate.ps1` in PowerShell, or `source .venv/bin/activate` on macOS/Linux. Then:

```sh
python -m pip install Pillow resvg-py
python tools/generate_focusjoy_branding.py
```

This updates multiple logo variants, launcher icons, and platform splash assets. Review all affected files. The animated Flutter splash is in `lib/widgets/focusjoy_splash.dart`; changing a static icon does not automatically redesign the animation.

## Optional local builds

These commands are for developers to run when needed; they are unnecessary for editing documentation or running host tests:

```sh
flutter build apk --debug
```

The default output is `build/app/outputs/flutter-apk/app-debug.apk`.

The checked-in **release configuration currently uses debug signing**. Before distributing a release, configure your own release signing in `android/app/build.gradle.kts`, keep signing material outside version control, and verify versioning and platform requirements. Once configured:

```sh
flutter build appbundle --release
```

Do not publish the current debug-signed release configuration as a production release.

## Troubleshooting

### Device is offline, or Flutter reports `error: closed`

Check for duplicate ADB installations, reconnect the cable, unlock the phone, and retry:

```sh
adb kill-server
adb start-server
adb devices -l
```

For `unauthorized`, approve the phone's prompt; if absent, revoke USB debugging authorizations in Developer options and reconnect. Use the same SDK Platform-Tools installation as Flutter. Restarting ADB disconnects other active ADB sessions too.

### SDK 36 is missing / plugins require a higher compile SDK

Install **Platform 36** in SDK Manager and confirm `compileSdk = 36` in `android/app/build.gradle.kts`. Do not lower it to 35 to silence dependency errors. AGP 8.7.0 may report a compile-SDK compatibility warning with API 36; review and test a toolchain upgrade together instead of suppressing the warning.

### Java or Gradle errors

Check Java in `flutter doctor -v` and use JDK 17. Restore dependencies and use the checked-in wrapper. Check available memory before increasing heap settings; the current project limits workers and heap to suit smaller machines.

### `SkeletonizerCanvas` / `UnitingCanvas` missing Canvas methods

Check `flutter --version` and run `flutter pub get` using the committed dependency files. The project declares `skeletonizer: ^2.1.3`; the earlier `1.4.3` version was incompatible with newer Flutter Canvas APIs. Do not patch the global Pub cache or remove the lockfile as a routine fix.

### Missing plugin errors after a native edit

Stop and relaunch to rebuild native code. Hot reload cannot register a new Android service or method channel. Confirm the command launches `lib/main.dart` on Android.

### Alarm or shortcut still fails

Recheck feature permissions and the in-app error text. Test on a real phone, return after permission changes, and record Android version, manufacturer, reproduction steps, and whether the app was backgrounded, swiped away, or explicitly stopped. Include sanitized `flutter run`/`adb logcat` output in an issue. Remove notification content, notes, installed-app lists, and other personal information before sharing logs.

### Stale build state

Use a clean rebuild only when there is evidence of stale generated/build state:

```sh
flutter clean
flutter pub get
flutter run -d YOUR_ANDROID_DEVICE_ID -t lib/main.dart
```

This removes build caches and makes the next build slower. Uninstalling or clearing app data removes local data; neither is a routine setup requirement.
