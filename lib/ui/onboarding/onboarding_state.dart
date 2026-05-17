/// The four headline roster types the user can pick on step 3. Only
/// [rotating] is wired through to step 4 in MVP — the others surface a
/// "coming soon" SnackBar on tap (see [RosterTypeScreen]).
enum RosterType { day, night, rotating, custom }

/// Mutable carrier for the user's selections as they progress through
/// onboarding. Held by `_OnboardingFlowState`; mutations happen via
/// `setState` on the controller, so this class itself is intentionally
/// dumb (no copyWith, no equality) — it's a state bag, not a value type.
///
/// Note: with the simplified step-4 flow (tap preset → date picker →
/// generation fires in one shot), the picker hands `(pattern, anchor)`
/// straight back to the flow controller. No need to carry those
/// selections through this state bag.
class OnboardingState {
  RosterType? rosterType;
}
