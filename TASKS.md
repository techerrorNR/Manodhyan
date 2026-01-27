## ManoDhyan Integration Taskboard

### Current ManoDhyan Strengths (keep as-is, layer on top)
- Focus timer + alarm stack (`lib/controllers/alarm_controller.dart`, `lib/services/alarm_service.dart`, math challenge dismissal).
- Task/streak + crystal gamification screens.
- Existing theming/assets (ManoDhyan palette, typography, iconography).

### ManoDhyan Modules to Adapt
1. **Infrastructure & permissions**
   - Wire ManoDhyan permission/onboarding flows (`lib/mind/ui/onboarding`, `lib/mind/ui/permissions`, `lib/mind/config/navigation`).
   - Ensure new dependencies (Riverpod, Drift, VPN services) compile with current app.
2. **Usage + restriction engine**
   - Integrate Drift database + providers (`lib/mind/core`, `lib/mind/providers/apps|usage|restrictions`).
   - Expose APIs so current screens/controllers can read restriction state.
3. **Blocking & insights UI**
   - Mount key screens (`lib/mind/ui/screens/app_dashboard`, `restriction_groups`, `shorts_blocking`, `websites_blocking`, `notifications`, `bedtime`).
   - Re-theme to match ManoDhyan colors without altering logic.
4. **System services**
   - Hook VPN, notification listener, quick tiles, tracker services (`lib/mind/services/*`) alongside existing alarm service.
5. **Merge ManoDhyan exclusives**
   - Reintroduce math challenge alarms, streak UI, and crystal rewards into the ManoDhyan navigation stack.
6. **Polish & QA**
   - Theming consistency audit, permissions testing, regression pass on focus/alarm flows.

### Execution Order
1. Permissions + onboarding shell
2. Usage/restriction data layer
3. Blocking & notification UI
4. System services wiring
5. ManoDhyan feature reintegration
6. Final theming + QA
