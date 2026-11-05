# Contributing to FocusJoy

Flutter/Dart work, native Android fixes, design, accessibility, translations, documentation, and careful device testing are all welcome. You do not need to propose a large feature to get involved.

## Start here

1. Read the [README](README.md) and [developer setup guide](docs/SETUP.md).
2. Check [open issues](https://github.com/techerrorNR/Manodhyan/issues) and pull requests for related work.
3. For a small fix, explain the problem in your PR. For a larger feature, dependency/toolchain upgrade, storage migration, or architectural change, open an issue first so maintainers can discuss the approach and avoid duplicate work.
4. Keep the change focused and explain how it helps people use their time intentionally.

Useful starting areas include onboarding, permission-denial flows, device compatibility, accessibility, localization of newer screens, documentation, and replacing the outdated starter widget test with a meaningful smoke test. These are suggestions, not assigned or pre-approved issues.

## Fork and create a branch

Fork on GitHub, then replace `YOUR_GITHUB_USERNAME` below:

```sh
git clone https://github.com/YOUR_GITHUB_USERNAME/Manodhyan.git
cd Manodhyan
git remote add upstream https://github.com/techerrorNR/Manodhyan.git
git fetch upstream
git switch -c fix/describe-your-change upstream/main
flutter pub get
```

Use a descriptive branch name such as `fix/alarm-permission-message`, `feat/planner-filter`, or `docs/linux-setup`.

## Make the change

- Follow the module's conventions. Both Provider and Riverpod exist; introducing another state-management approach needs discussion.
- Reuse the shared palette and navigation. Focus actions should open the existing Focus tab instead of introducing a second home shell.
- Keep user data compatible. Explain migrations and recovery behavior for storage changes.
- Keep reward calculation repeat-safe, preserve alarm error handling, and handle permission denial/revocation clearly.
- For Android changes, consider backgrounding, recreation, rotation, isolate boundaries, and platform version differences.
- Use accessible labels and readable contrast. Where localization is supported, update source ARB files rather than generated translations.
- Add meaningful tests for changed behavior. Documentation-only and straightforward visual edits do not need artificial tests.
- Keep unrelated refactors, mass formatting, package upgrades, and generated churn out of the PR.
- Never commit signing keys, `.env` files, local SDK paths, user databases, private logs, or build output. Keep the application lockfile tracked.

## Verify your work

Run `flutter analyze`, format changed Dart files, and run relevant tests. The established regression command is:

```sh
flutter test --no-pub test/focus_reward_test.dart test/notes_controller_test.dart test/mental_math_test.dart test/alarm_scheduling_test.dart test/floating_focus_test.dart
git diff --check
```

The old `test/widget_test.dart` expects Flutter's starter counter app. See [testing notes](docs/SETUP.md#6-analyze-and-test) before using a blanket `flutter test`. Report existing findings separately; do not describe checks you did not run as passing.

Device validation matters for Kotlin, alarms, overlays, notification/usage access, and restrictions. Include manufacturer, Android version/API, and scenarios tested. For UI changes, include screenshots or a short recording when possible. State clearly if a native build or device check could not be run.

## Commit and open a pull request

Review your changes, stage relevant files, and commit with a message describing the result:

```sh
git status
git diff
git add PATH_TO_CHANGED_FILE
git commit -m "Fix alarm permission recovery after returning from Settings"
git push -u origin fix/describe-your-change
```

Replace the example paths, branch, and message. Open a pull request from your fork to **`techerrorNR/Manodhyan:main`**. Include:

- The user problem and resulting behavior.
- A linked issue, if one exists (`Closes #123` only when resolved by the PR).
- Checks run, results, and remaining limitations.
- Screenshots for visible changes and device details for native behavior.
- Any migration, permission, dependency, or third-party source/license implications.

Maintainers may request adjustments before merging. Keep discussion respectful and reviews constructive. To update a personal branch, fetch upstream and merge or rebase carefully; avoid rewriting shared branch history.

## Reporting bugs and proposing features

Bug reports should include exact steps, expected/actual results, commit or app version, Flutter version, device/OS, permission state, and sanitized logs. For alarms or overlays, distinguish backgrounding, a recents swipe, and force-stop.

Feature proposals should explain the user need, interaction, testable behavior, and any new permissions, data collection, or services. Mindful games should respect the daily allowance. Avoid unsupported IQ or medical claims.

For sensitive security reports, contact **contact@sjtechnovation.in** privately rather than posting exploitable details or private data in a public issue. Do not attach production credentials.

## Credits and license

Contributions are made under the existing [GNU GPL v2 license](LICENSE). Preserve applicable notices and original authorship, including the Mindful foundation by [Pawan Nagar (@akaMrNagar)](https://github.com/akaMrNagar). Contribute only code/assets you have the right to share, and identify third-party sources and licenses. Do not replace credits with an exclusive ownership claim.

Continued development is led by [Rakesh Yadav (@techerrorNR)](https://github.com/techerrorNR) at [Shree Ji Technovation](https://sjtechnovation.in/). Contributors at every experience level are welcome.
