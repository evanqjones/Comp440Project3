# School environment and room events

Implemented on `School_System` and included in the F5 School demo. The earlier imported Blender preview is still separate. These are School-owned environment features, not a Monster controller.

## Monster-facing environment API

Use the `SchoolFoundation` instance after ready. Every returned position/path is world-space; query again as the player moves. Root translation and yaw rotation are supported; root scale must remain one.

| API | Contract |
| --- | --- |
| `get_room_id_at(position: Vector3) -> StringName` | Stable room region ID; empty outside. |
| `get_room_ids() -> Array[StringName]` | Ten IDs, including new `science_lab`; existing room IDs remain unchanged. |
| `get_stalking_locations(room_id: StringName = &"") -> Array[Dictionary]` | 48 copied records `{id, room_id, position, tags}`. Tags include `room`, `hallway`, `corner`, `intersection`, and `doorway`. Seven interior doorway markers plus 41 cell-center markers. |
| `get_traversable_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array` | Fresh synchronous AStar3D route. Empty means invalid/unreachable endpoints. Follow every segment; do not skip waypoints or smooth through walls. |
| `get_navigation_connections() -> Array[Dictionary]` | Copied world-space graph edges `{from, to, room_a, room_b}` for inspection/integration. |
| `get_door_connections() -> Array[Dictionary]` | Stable IDs and interior/exterior connections. All doors remain permanently open in this foundation. |
| `get_cell_position(cell: Vector2i) -> Vector3` | Configured grid-cell center, for authored anchors. |
| `set_debug_visible(enabled: bool)` | Show/hide the 3D debug graph and marker dots. |
| `show_debug_path(from_world, to_world) -> PackedVector3Array` | Draw and return the same physical route; empty paths clear the previous route. |

No method sets Monster state, speed, target, position, or relocation policy. The caller owns path refresh frequency and physical movement. No teleport code is added. The School's markers are clearance-valid locations, not promises of invisibility; the Monster must apply its own perception/visibility and candidate-selection rules. This is a waypoint graph, not a NavigationServer mesh or dynamic-obstacle avoidance service.

The same cell boundaries generate solid collision geometry and graph edges. The library's two full-height shelf partitions block both sight and their corresponding graph connections. Hall turns, intersections, walls, ceilings, and door jambs provide further sight breaks. Ray tests verify room-wall and maze-partition occlusion; capsule sweeps verify all unique routes between stalking candidates. Default supported agent radius is 0.35 m, height 2.2 m. Closed doors, safe rooms, moving obstacles, and a real Monster remain future integration work.

## Configurable layout

Select **SchoolFoundation → Layout** in the Inspector or open `assets/school_layout.tres`. Defaults are in `scripts/school/school_layout.gd`:

- Cell size, ceiling height, wall thickness, doorway width/height, supported navigation radius/height.
- Stable room IDs and `Rect2i` cell rectangles.
- Door IDs and adjacent cell pairs (`Vector4i(ax, az, bx, bz)`).
- Library partition edges and ordered maze checkpoint cells.
- Entrance cell, science-lab entry and goal cells.

Set layout values before running; reload the scene/restart after changing geometry. Layout changes are not a live rebuild feature. Layout validation reports invalid dimensions, overlapping rooms, invalid door/partition endpoints, and missing event anchors. Maintain reachability when authoring new topology and rerun the navigation tests. Color/label/debug-dot styles are presentation, not traversal tuning.

Select **RoomEvents** to tune checkpoint radius, watched movement tolerance, watch-report timeout, and reaction grace. The 0.35-second grace allows the existing player to stop as the watch signal changes. The demo root separately exports its simulated watch timing and debug-route refresh interval. These are provisional gameplay-tuning values.

## Room events and integration

`SchoolFoundation/RoomEvents` is the School-owned event service. Integration supplies the environment/player references with `bind_environment(school: Node3D, player: Node3D)`. It reads position but never writes either actor's transform.

**Library maze:** entering the south start activates an attempt. Follow six ordered checkpoint centers through the winding shelf passage; an east-door shortcut does not satisfy the ordered route. At the final marker, `request_reward(&"library_maze")` emits one book completion. A capture report or leaving the library fails the attempt. Return to the start and request retry. No chase timer or Monster chase logic is added.

**Science lab:** enter through Classroom 103 and step onto the start marker. Reach the coat while moving during look-away periods. Movement beyond the configured tolerance after the watch-change grace resets the attempt. Return to the start and press E to retry; actors are never teleported. Stationary waiting while watched is allowed. Collection requires a fresh look-away report; a missing/stale report is not permission to collect.

| Event API | Meaning |
| --- | --- |
| `report_lab_watch_state(watching: bool)` | Monster integration refreshes each physics tick with its own detection result. School does not calculate or command Monster gaze. |
| `report_player_caught(room_id: StringName)` | External capture aborts an active event in that room; no death/respawn implementation. |
| `get_challenge_snapshot(event_id: StringName) -> Dictionary` | `{id, state, next_checkpoint, target_position, watch_known, watching}`; states are `idle`, `active`, `failed`, `completed`. Unknown ID returns empty. |
| `request_retry(event_id: StringName) -> bool` | Failed attempt restarts only when the bound player has returned to the entry marker. |
| `request_reward(event_id: StringName) -> bool` | Validates active attempt, route/watch requirements, and proximity; returns success once. |
| `challenge_started(event_id: StringName)` | One event when an attempt begins. |
| `challenge_failed(event_id: StringName, reason: StringName)` | Reasons: `caught`, `left_room`, `moved_while_watched`. State is committed before notification. |
| `challenge_completed(event_id: StringName, reward_id: StringName)` | Reward hook: `book` or `lab_coat`. Does not implement the shared inventory/checkpoint/objective sequence. The demo increments its test-progress counter. |

The demo explicitly labels its lab signal **SIMULATED**: a red/green lamp and status alternate to let you test the event without a Monster. Set `simulate_lab_watch = false` on the demo root when wiring real perception; do not leave two signal providers active. Press C in a room to simulate an external capture report. This does not spawn, move, or change a Monster. These new event hooks are isolated School APIs; existing shared contract signatures remain unchanged.

## Manual verification in Godot

1. Open `project.godot` on `School_System`, press **F5**. Start in Entrance. Use WASD/mouse; Escape releases the mouse.
2. Press **N**: cyan lines show valid graph edges, green dots show room/hall/corner markers, pink dots mark doorways, and gold shows a requested route. Room IDs are readable 3D labels and appear in the demo overlay. Debug lines respect depth/occlusion and are not a minimap.
3. Initially gold leads from your current position to the library book. Follow it from Entrance through the east/main halls and library doorway. It must turn through valid gaps, never cross shelves/walls. This shortest navigation route is independent of the ordered maze event route.
4. Press **V** to cycle destinations: library book → science coat → entrance. Walk while debug is enabled; gold routes refresh every 0.25 seconds from your new position. Verify Entrance ↔ Library, Library ↔ Science Lab through Classroom 103, and Science Lab ↔ Entrance. Both library doors and the north/west hallway loop remain connected.
5. Enter Library from its south door in the main hallway. Follow the gold **checkpoint beacons** (separate from the optional debug line) in order. At BOOK [E], press E. The beacon disappears, one reward hook prints, and demo progress increments once. Pressing E again must not award again. To test capture/reset, press C before collecting, then walk back to RETRY HERE [E].
6. Enter Classroom 103 from the main hallway; its far doorway leads to Science Lab. Step onto SCIENCE LAB START. Move on green/look-away; stop on red/watching. Deliberately keep moving on red after the short grace: the attempt resets. Walk back to the retry beacon, press E, retry, then reach LAB COAT [E] and collect while looking away. There is no real pursuing Monster yet.
7. Change a layout dimension in the Inspector, restart, and inspect the updated geometry, room boundaries, and routes together. Keep checkpoint anchors and door endpoints inside valid rooms. Run tests after topology changes.

## Automated verification

Run with the Godot executable and `--headless --path . --script` followed by each test:

- `res://tests/school_foundation_test.gd`: all 48 candidate pairs reachable; 147 unique segments capsule-swept; stalking categories; maze LOS/detour; connectivity; transformed queries; alternate dimensions.
- `res://tests/school_room_events_test.gd`: ordered maze, shortcut rejection, one-shot rewards, watched-movement reset, no player reposition, retry proximity, stale watch rejection, capture/leave resets.
- `res://tests/school_demo_test.gd`: F5 integration, active camera, room/Bell displays, progress inputs.
- `res://tests/school_bell_test.gd`: exact-once transitions, random scheduling, progress, pause/cancellation.

New files: `scripts/school/school_layout.gd`, `assets/school_layout.tres`, `scripts/school/school_room_events.gd`, `tests/school_room_events_test.gd`, this handoff, and the library/lab README screenshots (plus generated script UID sidecars). Updated School foundation, demo scenes/scripts, existing navigation tests, root README, and School handoff notes. Player controller and Monster files are unchanged.
