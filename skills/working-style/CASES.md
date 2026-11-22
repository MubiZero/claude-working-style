# Historical Cases (Context Only, Not Loaded in Sessions)

- **Hardcoded strings next to live i18n (T15, T16):** Operator UI used hardcoded strings while `@afk4/i18n` was active. Fix the root and use the catalog instead of adding more hardcode.
- **Fragmented strings & manual pluralization (L7):** Concatenated JSX fragments with custom `pluralRu` helpers break translation. Propose full-sentence ICU MessageFormat instead of copying the workaround.
- **Fake locale parity by copying Russian into English/Tajik (R2):** Turns CI green while shipping broken UI. Leave the gap visible or translate properly.
- **Role asymmetry discovered in production (T18):** "Submit work" button existed for the worker, while the foreman viewing an overdue task only had "Close without submission" with no note or photo. Always walk adjacent roles when building role-gated actions.
- **Separate tab breaking the user's core loop (T23, T24, T25):** Moving active POS orders to a separate tab forced cashiers into a multi-screen detour on every order. Trace the 5–8 step loop and count main-screen departures before proposing navigation changes.
