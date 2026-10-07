# Progress and Handoffs

**Package baseline:** documentation created 2026-10-05 from the referenced design conversation and uploaded formatting/workflow examples. No game repository/source code was present in the current workspace at package creation.

**Asset handoff:** User owns asset production and may use AI tools. Teammates' default scope is their assigned code systems; see `ASSETS.md`.

## Evan — Monster System

- **Status:** Not started (implementation)
- **Done:** Monster behavior and ownership brief documented.
- **In progress:** None.
- **Next:** Inspect project, establish Monster scene/controller against agreed contracts; begin with patrol/perception slice.
- **Needs from others:** Zion's room/door IDs and navigation representation; Rhaiyn's player/noise interface; team decisions for perception and timing values.
- **Handoff notes:** No teleport during Bell chase. Outside Bell, relocation only offscreen; if the candidate is visible, choose another location. Safe-room exclusion comes from Zion's active safe-room set.

## Zion — School System

- **Bell slice:** Added configurable `SchoolBell` scheduler and scene, instanced in the School foundation; see [Bell handoff](../../SCHOOL_BELL.md). Owns read-only `bell_active`, typed `bell_state_changed`/`get_bell_snapshot`, random waits, fixed configurable duration, and objective-progress scaling of future interval bounds. No Monster/Player control. Added `tests/school_bell_test.gd`; Godot 4.7.2 verified 114 transitions with zero failures, including real engine processing and pause. Timing values remain provisional; final escape, safe rooms, duration progression, and objective-source wiring are not implemented in this slice.
- **Status:** Small standalone School foundation implemented (2026-10-06); broader progression remains unimplemented.
- **Foundation handoff:** See [SCHOOL_FOUNDATION.md](../../SCHOOL_FOUNDATION.md). Created `scripts/school/school_foundation.gd`, `scenes/school_foundation.tscn`, `tests/school_foundation_test.gd`, and the handoff. Nine room/hall IDs, 37 stalking candidates, seven open door connections including one exit, collision geometry, room tracking, and AStar3D world-space routes. This user-requested small graybox is provisional and separate from the imported full floorplan. Existing frozen signatures and other owners' files are unchanged.
- **Foundation verification:** Godot 4.7.2 headless test passed with zero failures: all candidate pairs reachable, 123 unique capsule-swept segments clear, room lookup/tracking/removal, invalid endpoint rejection, wall sight blocking, and transformed queries. Host emitted a root certificate-store warning unrelated to these offline checks. Manual editor/walking verification remains pending.
- **Asset handoff (2026-10-06):** Blender school blockout and Godot preview are now available. See [`WORK_LOG.md`](../../WORK_LOG.md) for the edit history and exact file handoff. The blockout includes room geometry, roofs, door openings/swing markers, and window gaps. Godot uses the exported GLB and placeholder capsule/camera. Gameplay room/door IDs, interactive door state, keys, progression, Bell behavior, and checkpoint logic remain unimplemented.
- **Done:** School behavior and ownership brief documented.
- **In progress:** None.
- **Next:** Manually walk the isolated foundation and coordinate integration of its room/stalking/path queries; separately confirm full-floorplan IDs, starting route, lock assignment, and door interaction slice.
- **Needs from others:** Evan's room graph/navigation needs; Rhaiyn's interaction/noise/HUD contract consumers.
- **Handoff notes:** Door opens permanently and is loud once on successful open. School is authority for Bell, safe-room IDs, progression, and world checkpoint snapshot. Exact cadence/safe-room selection remains open.

## Rhaiyn — Player System

- **Status:** Not started (implementation)
- **Done:** Player behavior and ownership brief documented.
- **In progress:** None.
- **Next:** Inspect project and implement walk/sprint/stamina and horizontal camera slice against existing conventions.
- **Needs from others:** Zion's stable room/target IDs and objective/item marker APIs; Evan's chase speed target for tuning.
- **Handoff notes:** Emit walking as quiet and sprinting as loud without per-frame event spam. Door opening and successful item pickup loudness should be emitted exactly once by the authoritative interaction path. Minimap never contains monster data.

## Integration owner — OPEN

- **Status:** Unassigned
- **Next:** Team selects who owns the main/root scene, project settings, cross-system wiring, and final playable integration.

## Verification baseline

- Documentation package consistency checked by link/file review at creation.
- No Godot project or tests were available in this workspace, so no game execution or gameplay verification is claimed.
