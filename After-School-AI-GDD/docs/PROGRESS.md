# Progress and Handoffs

**Package baseline:** documentation created 2026-10-05 from the referenced design conversation and uploaded formatting/workflow examples. No game repository/source code was present in the current workspace at package creation.

**Asset handoff:** User owns asset production and may use AI tools. Teammates' default scope is their assigned code systems; see `ASSETS.md`.

## Evan — Monster System

- **Status:** Preview patrol started; full behavior and School navigation integration remain in progress
- **Preview prototype (2026-10-07):** Added a stationary 3 m capsule with an opaque triangular search cone in the Godot preview. Z toggles preview-only red Bell lighting/status; this does not implement authoritative Bell state, timer, safe rooms, movement, detection, collision, capture, or reset.
- **Done:** Monster behavior and ownership brief documented.
- **In progress:** Added a slow, reversible preview patrol and a visible-POV transition into short chase. Monster spawn sits toward the Classroom D side of the Lobby. Patrol, short chase, and Bell chase speeds are provisionally 0.5, 4.5, and 6.5 m/s. The preview bakes the school collision geometry into a navmesh for Bell pursuit and squeezes the capsule through narrow modeled doorway gaps. Verified a 325-polygon bake and a 7-point route from the Lobby spawn to the Nurse Office player start. This preview has no authoritative door-state or safe-room data; production integration still needs Zion's room/door/nav queries. Connect Rhaiyn's player/noise interface before noise investigation.
- **Next:** Coordinate with Zion to replace preview geometry navigation with stable room/door/nav queries and live door state, then add safe-room avoidance. Connect Rhaiyn's player/noise interface before noise investigation.
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
- **In progress:** Tuned provisional walk and sprint speeds to 3.5 m/s and 5.5 m/s. Holding Shift selects sprint speed.
- **Next:** Add stamina and publish quiet-walk/loud-sprint noise through the agreed player interface.
- **Needs from others:** Zion's stable room/target IDs and objective/item marker APIs; Evan's chase speed target for tuning.
- **Handoff notes:** Emit walking as quiet and sprinting as loud without per-frame event spam. Door opening and successful item pickup loudness should be emitted exactly once by the authoritative interaction path. Minimap never contains monster data.

## Integration owner — OPEN

- **Status:** Unassigned
- **Next:** Team selects who owns the main/root scene, project settings, cross-system wiring, and final playable integration.

## Verification baseline

- Documentation package consistency checked by link/file review at creation.
- No Godot project or tests were available in this workspace, so no game execution or gameplay verification is claimed.
