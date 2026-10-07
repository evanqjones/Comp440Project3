# Decisions and Open Questions

This log separates confirmed design from assistant-proposed implementation structure. Do not promote an **OPEN** item to confirmed without team agreement.

## School prototype request — 2026-10-07

The School owner explicitly requested environment-side Monster support plus a library maze/book event and a science-lab move-when-not-watched event in the running School_System demo. The owner confirmed that moving while watched resets the lab attempt. This authorizes the isolated School prototype, not a rewrite of the larger floorplan or shared inventory/checkpoint rules. The prototype resets event progress without repositioning actors; the player walks back to the start to retry. School receives watch/capture reports and publishes completion hooks. Real Monster perception, pursuit, relocation, and capture resolution remain Monster/Player responsibilities. New School extension APIs are documented in `../../SCHOOL_MONSTER_SUPPORT.md`; no frozen signatures change. Demo gaze is explicitly simulated; layout/timing values remain tunable prototypes.

## Confirmed design decisions

| ID | Decision |
|---|---|
| D-001 | Game is third-person school horror titled *After School*. |
| D-002 | Player begins in Nurse Office after oversleeping while sick. |
| D-003 | First objective: keys in Main Office. |
| D-004 | Belongings/locations: Weight—Locker Room; Book—Library; Brush—Art Room; Lab Coat—Lab Room; Ruler—Classroom; Snack—Cafeteria. |
| D-005 | Final objective after belongings: reach exit. |
| D-006 | Each collected belonging becomes newest checkpoint; capture triggers jumpscare and reset to last item checkpoint/world state. |
| D-007 | Sprint and stamina exist; camera rotates horizontally; minimap is top-left and communicates objective/item rooms, never monster location. |
| D-008 | Walking quiet. Sprinting, opening a door, and collecting an item loud. |
| D-009 | Doors do not close after opening. Keys allow opening locked doors. Opening is loud. |
| D-010 | Monster cannot operate doors; it can walk through rooms/open doorways. |
| D-011 | Monster may kill outside Bell. Nearby loud noise turns its attention toward the sound; seeing player in POV can initiate chase. |
| D-012 | Stalking relocation should be fairly common, only offscreen; when visible, choose another location. Flicker is less frequent, around 10% when spotted, and only sometimes conceals relocation. |
| D-013 | Bell starts at 10 seconds; duration increases 2 seconds with progression until final escape; final Bell is indefinite until escape. |
| D-014 | Normal school mood is dark blue-ish and yellow-ish; Bell pursuit changes school lighting to red. |
| D-015 | Random rooms light as active safe rooms during Bell; monster cannot enter an active safe room. If the player must open its closed door, opening remains required/loud. |
| D-016 | Normal short chase is a little faster than walking; Bell chase a little faster than sprint. During Bell the monster pathfinds and cannot teleport. |
| D-017 | The supplied hand-drawn school map is the relative layout source of truth. Recreate its placements and adjacency as transcribed in `MAP_RECREATION.md`; do not redesign the layout. |

## Implementation interpretations (not new design approvals)

- **I-001:** separate patrol, investigate, short chase, Bell chase, and capture states to implement the behavior clearly.
- **I-002:** Zion owns authoritative School state; Evan owns monster behavior; Rhaiyn owns player behavior and presentation.
- **I-003:** shared interfaces in `CONTRACTS.md` are proposed API shapes to coordinate implementation; adjust only through the contract change protocol.
- **I-004:** treat checkpoint as a coherent world snapshot; exact fields and key/Bell/monster treatment still require a decision.

## Open questions requiring team decision

| ID | Question | Suggested owner(s) |
|---|---|---|
| O-001 | What are exact scale, wall thickness, door widths, and the few ambiguous openings/divisions in the supplied plan? Relative floorplan and room arrangement are now transcribed. | Zion/team |
| O-002 | Which doors are locked, and what route is guaranteed before obtaining keys? | Zion/team |
| O-003 | Must belongings be collected in order? Are all item pins visible from start? | Team |
| O-004 | Does finding keys create a checkpoint or persist after death to Nurse Office fallback? | Team |
| O-005 | Which gameplay event triggers each Bell, how often, and when can first Bell occur? | Zion/team |
| O-006 | Does +2 seconds apply after every belonging (including the last), every objective, or another progression step? | Zion/team |
| O-007 | How many safe rooms activate; which rooms are eligible; do they remain fixed for Bell duration? | Zion/team |
| O-008 | What if player is already inside an active safe room when Bell begins? | Team |
| O-009 | On timed Bell end, does monster immediately return to patrol, and what state is restored after checkpoint? | Team |
| O-010 | Exact checkpoint snapshot fields and order of restore operations? | Team |
| O-011 | Exact movement/stamina/camera and monster speeds, radii, FOV, attack range, relocation cadence, noise probabilities, chase timeout? | Rhaiyn/Evan |
| O-012 | Flicker sampling cooldown and whether it is cosmetic alone or may conceal relocation on a given event? | Evan |
| O-013 | Exact lighting colors, transition sequence/duration, audio assets and mix? | Team |
| O-014 | Which teammate owns root scene, project settings, cross-system wiring, and release integration? | Team |
| O-015 | What Godot 4 minor release, renderer, platforms, and test framework does the actual repo use? | Team |

Record each resolution below with date, decision, and affected docs/code. Keep old decisions for history.

## Decision log entries

_(No additional team decisions recorded yet.)_
