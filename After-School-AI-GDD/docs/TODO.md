# Backlog

Items marked **DECISION** require human/team agreement before they can be made final. Owners may prototype behind exported settings while waiting, but must label the setting provisional.

## Foundation

- [x] **Zion:** categorized stalking points, exported physical connectivity, configurable geometry, library maze and science-lab environment challenges, plus F5 debug inspection and School event hooks. Real Monster watch/capture providers and full reward/checkpoint integration remain to be wired.
- [x] **Zion:** user-requested small standalone School foundation with stable room IDs, player-room lookup, stalking candidates, physical waypoint routes, solid walls/corners, and one exit. See [handoff](../../SCHOOL_FOUNDATION.md); this provisional graybox does not complete the larger floorplan migration below.
- [ ] **Zion/team:** translate `docs/MAP_RECREATION.md` into room/door IDs and a traversable graybox; preserve the supplied relative placements and mark unresolved door/layout ambiguities for review.
- [ ] **DECISION — Team:** choose integration owner for root scene/project settings/shared wiring.
- [ ] **DECISION — Team:** pin exact Godot 4 minor version, renderer/export targets, repository layout, and test workflow after inspecting repo.
- [ ] **DECISION — Team:** confirm whether belongings must be collected in sequence or may be collected out of order.
- [ ] **DECISION — Team:** define whether keys become a checkpoint/progress flag and what persists on the Nurse Office fallback checkpoint.

## Milestone 1 — Playable traversal

- [ ] **Rhaiyn:** third-person walking, horizontal camera, collision-aware view.
- [x] **Rhaiyn:** sprint/stamina slice with exported provisional capacity/drain/regeneration/delay/recovery threshold and existing WASD/Shift controls (2026-10-07); Player parser/scene checks and 21 headless physics checks passed. A later headless run confirmed the merged school preview starts; manual stamina/crouch/noise tuning and input remapping/settings remain deferred. See Rhaiyn's `PROGRESS.md` section for provisional defaults/policy and verification details.
- [ ] **Zion:** Nurse Office spawn, Main Office key placement, room/door data, start route traversable.
- [ ] **Zion:** locked/open door behavior, permanent-open invariant, successful open event/noise.
- [ ] **Rhaiyn/Zion:** Player camera targeting, minimal E prompt, and frozen `interaction_requested(target_id: StringName)` request are ready (2026-10-08; 45 headless checks passed). Zion/integration's stable production target IDs and wiring through School's public `request_interaction` API remain pending; joint task stays open.

## Milestone 2 — Items and checkpoints

- [ ] **Zion:** six specified item placements and objective progression.
- [ ] **Rhaiyn:** top-left minimap, objective display, item markers; no monster marker/data.
- [x] **Rhaiyn:** stamina-only Player HUD with current/capacity bar/text and exhaustion/recovery feedback (2026-10-08); 28 HUD checks passed headless and natively, plus 45 Player regression checks. Visuals remain provisional; this does not complete minimap/objective/Bell UI or joint School integration.
- [ ] **Zion/team DECISION:** finalize checkpoint fields, key treatment, restore Bell phase/timer, and monster reset behavior.
- [ ] **Zion/Rhaiyn:** save latest item checkpoint; capture → jumpscare → restore world/player in a single guarded flow.
- [ ] **Zion:** final exit gated until all belongings complete.

## Milestone 3 — Monster stalking

- [ ] **Evan:** patrol across valid school paths; closed doors block; open doors connect.
- [ ] **Evan:** receive noise events, orient/investigate nearby loud sources, enter short chase on POV.
- [ ] **Evan:** offscreen-only stalking relocation and candidate visibility rejection.
- [ ] **Evan:** approximately 10% flicker target on spotting, with relocation concealment only sometimes.
- [ ] **DECISION — Evan/team:** sound radii/probabilities, patrol/relocation cadence, FOV, proximity capture, short chase timeout/escape rules.

## Milestone 4 — Bell chase

- [x] **Zion (2026-10-09, user authorized):** integrate School scheduler, Bell audio/lighting, real pickup pressure, full-building queries and gated final exit into the existing larger team game on School_System; F5 uses the combined scene. Existing encounters preserved. See root School_System handoff for verified behavior and provisional tuning.

- [x] **Zion:** isolated Bell scheduler: configurable random intervals/duration, exact-once typed state transitions, and objective-progress scaling of future intervals; automated tests and [manual steps](../../SCHOOL_BELL.md). Full Bell progression/integration below remains outstanding.
- [ ] **Zion:** authoritative Bell state, 10-second start, +2 seconds by progression, indefinite final Bell.
- [ ] **DECISION — Zion/team:** Bell first-trigger/cadence and progression step mapping.
- [ ] **Zion:** random eligible active safe-room selection and consistent publication.
- [ ] **DECISION — Zion/team:** safe-room count, eligibility, reselection, and occupied-room behavior.
- [ ] **Zion:** normal blue/yellow and Bell red lighting modes; active safe rooms remain visibly distinct.
- [ ] **Evan:** Bell chase pathfinds to player, slightly above sprint, no teleport, avoids active safe rooms.
- [ ] **Rhaiyn:** Bell objective/safe-room cue and transition presentation.

## Milestone 5 — Finish and tune

- [ ] **Team:** basic event audio for walking/sprinting/door/item/Bell/jumpscare.
- [ ] **Team:** successful final exit ends game and communicates victory.
- [ ] **Team:** agree exact tuning table values after playable feedback; update GAME_SPEC and DECISIONS.
- [ ] **Team:** verify restart consistency, door/nav interactions, safe-room protection, and minimap privacy in full game.

## Deferred / not approved

- Menus, pause, save-to-disk, multiple endings, extra objectives, or new monster abilities: not in approved scope.
