# Progress and Handoffs

**Package baseline:** documentation created 2026-10-05 from the referenced design conversation and uploaded formatting/workflow examples. No game repository/source code was present in the current workspace at package creation.

**Asset handoff:** User owns asset production and may use AI tools. Teammates' default scope is their assigned code systems; see `ASSETS.md`.

## Evan — Monster System

- **Status:** Preview patrol started; full behavior and School navigation integration remain in progress
- **Preview prototype (2026-10-07):** Added a stationary 3 m capsule with an opaque triangular search cone in the Godot preview. Z toggles preview-only red Bell lighting/status; this does not implement authoritative Bell state, timer, safe rooms, movement, detection, collision, capture, or reset.
- **Done:** Monster behavior and ownership brief documented.
- **In progress:** Added a slow, reversible preview patrol and a visible-POV transition into short chase. Monster spawn sits toward the Classroom D side of the Lobby. Patrol, short chase, and Bell chase speeds are provisionally 0.5, 4.5, and 6.5 m/s. The preview bakes the school collision geometry into a navmesh for Bell pursuit and squeezes the capsule through narrow modeled doorway gaps. Verified a 325-polygon bake and a 7-point route from the Lobby spawn to the Nurse Office player start. This preview has no authoritative door-state or safe-room data; production integration still needs Zion's room/door/nav queries.
- **Movement-noise preview integration (2026-10-07):** The preview Monster now consumes the Player's typed `NoiseEvent`: nearby quiet walking noise can make it turn toward the source, while loud sprint noise reuses the existing door-noise investigate/relocate response. Both are ignored during Bell. Response chance and distance remain provisional preview settings.
- **Spawn-point preview slice (2026-10-07):** Added temporary green panels at room-relative candidates for corridor corners/intersections, classroom doorways and windows, room interiors, behind-player, locker-bank hall side, and pillar sightlines. Candidates are checked against the excluded room floors and snapped only when close to the baked navigation surface. X tries a manual preview relocation only in PATROL; it checks the monster's current and destination capsule sample points against the active player camera frustum and wall occlusion. Bell state blocks relocation. M toggles the panels. These are preview candidates, not authoritative School room/safe-room data; no automatic stalking cadence was added.
- **Timed offscreen relocation preview (2026-10-07):** The preview now attempts relocation every 10 seconds while outside SHORT_CHASE and BELL_CHASE. The timer pauses during both chase states. Each attempt uses a randomized spawn candidate and keeps the existing camera-frustum and wall-occlusion checks for both the monster's current body and destination; Bell blocks relocation. Startup waits for navigation synchronization so the candidates are available before the timer runs.
- **Timed relocation verification (2026-10-07):** Ran the preview with game time controlled. At 9.8 seconds the monster stayed at its start point; after crossing 10 seconds it moved to a spawn marker that evaluated off-camera. With state set to SHORT_CHASE, advancing 12 seconds left both timer and position unchanged. With Bell active at 9.5 seconds, advancing 12 seconds also left timer and position unchanged. Editor error log had no new errors.
- **Hallway corner candidates (2026-10-07):** Added four additional preview candidates at corridor turns between the auditorium/gym wing, cafe/science wing, C/D classrooms, and science/Classroom E. They use circulation-floor coordinates, then the existing navigation snap and forbidden-room checks; off-camera eligibility is still enforced by the relocation method. Runtime showed all four new panels and 29 total candidates; editor error log was empty.
- **Hallway relocation bias and countdown (2026-10-07):** Automatic preview relocation tries a shuffled hallway-corner candidate pool first 75% of the time, falling back to the other candidates if all hallway choices are visible. The debug overlay now displays the live time until the next attempt and shows paused state during Bell/chase. Runtime confirmed the countdown decreases during game time and the editor error log is empty.
- **Door-noise investigation approach (2026-10-07):** When a 70% door-noise response relocates the monster to a safe nearby spawn, it now enters INVESTIGATE and follows the navigation path toward the sound at a provisional 0.5 m/s. The approach timer begins after it reaches the sound, and hallway pacing resumes afterward when the spawn was in a hall.
- **Open-door traversal (2026-10-07):** Added 24 door-state navigation links, enabled only after their doors finish opening. The monster now squeezes beneath low door headers before arrival in both investigation and Bell chase. Closed door leaves remain physical blockers. The Locker Room door waits for an active monster crossing before closing. Headless movement confirmed the monster is blocked by the closed Auditorium door and crosses it after it opens.
- **Smaller doorway squeeze (2026-10-07):** Reduced the minimum capsule width to 15% and height to 1.2 m for tight doorways. Headless movement check confirmed the monster remains blocked by a closed door, crosses after it opens, reaches 1.2 m while squeezing, and returns to its 3 m height afterward.
- **Bell safe-room window lurk preview (2026-10-07):** Z now selects three random preview-safe rooms with walkable perimeter routes, excluding the Lobby, and adds a warm room light. Seven hallway-facing window sites in the current model receive purple floor tiles; 38 additional perimeter waypoints support a slow 0.35 m/s loop around a selected room when the player is inside it. Active safe-room doorway nav links are disabled so the monster cannot route into those rooms. Headless run confirmed exactly three selected rooms, and a safe-room target check confirmed the monster destination and current position were outside that room. This remains preview-only until School publishes authoritative Bell/safe-room state.
- **Next:** Coordinate with Zion to replace preview geometry navigation with stable room/door/nav queries and live door state, then integrate noise against authoritative room/door data.
- **Needs from others:** Zion's room/door IDs and navigation representation; Rhaiyn's player/noise interface; team decisions for perception and timing values.
- **Handoff notes:** No teleport during Bell chase. Outside Bell, relocation only offscreen; if the candidate is visible, choose another location. Safe-room exclusion comes from Zion's active safe-room set. Preview short chase reads the Player node only as the approved target transform, uses the displayed cone plus collision ray, and has no capture effect. Bell preview pathfinding uses static school geometry and open doorway gaps; authoritative door-state and safe-room integration is still pending. No monster location enters HUD/minimap.

## Zion — School System

- **Status:** Not started (implementation)
- **Asset handoff (2026-10-06):** Blender school blockout and Godot preview are now available. See [`WORK_LOG.md`](../../WORK_LOG.md) for the edit history and exact file handoff. The blockout includes room geometry, roofs, door openings/swing markers, and window gaps. Godot uses the exported GLB and placeholder capsule/camera. Gameplay room/door IDs, interactive door state, keys, progression, Bell behavior, and checkpoint logic remain unimplemented.
- **Done:** School behavior and ownership brief documented.
- **In progress:** None.
- **Next:** Supply/confirm floorplan, room/door IDs, starting route, lock assignment, and exit location; implement room/door interaction slice.
- **Needs from others:** Evan's room graph/navigation needs; Rhaiyn's interaction/noise/HUD contract consumers.
- **Handoff notes:** Door opens permanently and is loud once on successful open. School is authority for Bell, safe-room IDs, progression, and world checkpoint snapshot. Exact cadence/safe-room selection remains open.

## Rhaiyn — Player System

- **Status:** Placeholder locomotion available; speed tuning and sprint binding verified in progress
- **Done:** Player behavior and ownership brief documented.
- **In progress:** Tuned provisional walk and sprint speeds to 3.5 m/s and 5.5 m/s. Holding Shift selects sprint speed. In the preview controller, Ctrl crouches at 2.0 m/s and lowers the capsule/camera. Walking and sprinting emit typed quiet/loud `NoiseEvent`s every 0.8 seconds while moving; crouching emits none.
- **Next:** Add stamina and connect the Player noise signal to production Monster integration through the agreed interface.
- **Needs from others:** Zion's stable room/target IDs and objective/item marker APIs; Evan's chase speed target for tuning.
- **Handoff notes:** Emit walking as quiet and sprinting as loud without per-frame event spam. Door opening and successful item pickup loudness should be emitted exactly once by the authoritative interaction path. Minimap never contains monster data.

## Integration owner — OPEN

- **Status:** Unassigned
- **Next:** Team selects who owns the main/root scene, project settings, cross-system wiring, and final playable integration.

## Verification baseline

- Documentation package consistency checked by link/file review at creation.
- No Godot project or tests were available in this workspace, so no game execution or gameplay verification is claimed.
