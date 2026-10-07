# School System foundation

Open `scenes/school_foundation.tscn` in Godot's 3D editor. The tool script generates the graybox in the editor and at runtime. It has no player, camera, Monster, UI, bell, inventory, or audio logic. F5 still opens the existing imported-model preview. Instance this scene into an integration scene when ready.

This is the small provisional layout requested for the foundation, not a replacement for `assets.blend`, its GLB, or the larger documented floorplan. All six internal doorways and the exterior doorway are permanently open in this slice. Door interactions/locks and progression remain future work; no existing frozen contract is changed. Placeholder dimensions and topology live in `_build()` and the constants in `scripts/school/school_foundation.gd`.

## Layout and stable IDs

- `hall_main`: east/west spine with classroom branches and a T intersection at `hall_west`.
- `hall_east`, `hall_north`, `hall_west`: connected return loop with blind corners.
- `classroom_101`, `classroom_102`, `classroom_103`: three 8 × 8 m classrooms.
- `library`: 12 × 8 m room, with south and east doors providing another route.
- `entrance`: 4 × 4 m lobby and the only exterior opening, `exit_main`.

Interior door IDs: `door_101`, `door_102`, `door_103`, `door_library_south`, `door_library_east`, `door_lobby`. Walls are 0.2 m thick and 3.2 m high, door openings 2 m wide and 2.5 m high. Floors, ceilings, jambs, and lintels have collision on layer 1. Solid room boundaries and corridor turns block sight naturally; this does not depend on renderer occlusion culling. Simple labels and warm lights identify the placeholder spaces.

## Public interface: SchoolFoundation

Call after the scene is ready. Positions are world-space, feet on the floor. Root translation and yaw rotation are supported; keep scale at one and the floor horizontal.

| API | Result / meaning |
| --- | --- |
| `get_room_ids() -> Array[StringName]` | Nine stable room/hall IDs. |
| `get_room_id_at(world_position: Vector3) -> StringName` | Canonical School room query. Empty outside the floorplan/vertical bounds. Half-open bounds assign thresholds deterministically; this is a spatial region query, not a collision test. |
| `set_player_target(player: Node3D) -> void` | Optional binding to any existing player; pass null to unbind. Does not move or modify the actor. |
| `get_current_room_id() -> StringName` | Bound actor's room, refreshed each physics tick; empty for missing/freed actor or outside. |
| `player_room_changed(previous_room: StringName, current_room: StringName)` | Emitted only when tracked room changes. |
| `get_stalking_locations(room_id: StringName = &"") -> Array[Dictionary]` | Copied records `{id: StringName, room_id: StringName, position: Vector3}`; empty filter means all 37 locations, unknown room returns empty. IDs use `stalk_<room>_<grid_x>_<grid_z>`. |
| `get_door_connections() -> Array[Dictionary]` | Copied records `{id, room_a, room_b, position, open, cell_a, cell_b}`. IDs are StringName, position Vector3, open bool, cells Vector2i. Exit has room_b `outside`. |
| `get_traversable_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array` | Ordered world-space floor waypoints, including endpoints. Empty for invalid/unreachable endpoints. Follow every segment; do not skip corners or smooth through walls. |
| `get_entrance_position() -> Vector3` | Interior lobby floor spawn/integration anchor. Does not trigger victory. |

Navigation uses a synchronous `AStar3D` graph, not NavigationServer or a baked NavigationMesh. Cell-center links cross only open shared space or the center of authored doorways. There is no navigation bake delay. Supported agent radius is at most 0.35 m and height at most 2.2 m. Endpoint height must be between -0.1 and 2.2 m above the floor; valid paths project it to floor height. Wall-clearance and outside checks reject invalid endpoints rather than snapping through walls. Exterior terrain is not modeled or routed.

The Monster owner selects candidates, checks visibility and distance, and follows routes with its own movement/collision. These are physically valid stalking candidates, not promises that a location is currently offscreen. Dynamic blockers, closed doors, safe-room exclusion, and larger agents are outside this static foundation. Future door state must update both geometry and graph before being offered to consumers.

```gdscript
# References are supplied by the integration owner, not found in another system's tree.
school.set_player_target(player)
var candidates: Array[Dictionary] = school.get_stalking_locations(&"library")
var route: PackedVector3Array = school.get_traversable_path(
    monster.global_position, candidates[0].position)
```

## Verification and manual steps

Automated: run Godot with `--headless --path . --script res://tests/school_foundation_test.gd`. Checks cover all-pairs candidate reachability, swept 0.35 m radius / 2.2 m height capsule clearance on unique path segments, room IDs, wall occlusion, invalid endpoints, actor tracking/removal, and translated/rotated queries. Expected: 37 locations, zero failures.

1. Open the foundation scene in the 3D editor; inspect the main spine, T intersection, loop, three classrooms, two library doorways, and single exterior doorway. Editor fly navigation can enter below the ceilings; the standalone scene intentionally has no game camera.
2. For a walking test, create an unsaved test scene and instance the foundation plus the **existing** `scenes/player_placeholder.tscn`. Set the player's position to `(26, 0.05, 26)`. Run that test scene; use its existing WASD/mouse controls. No Player files need editing.
3. Walk from the entrance up the east hall, turn west along the main hall, visit all classrooms, and enter the library from both doors. Walk the north/west return loop. Verify wall collision, doorway clearance, and that corners/room walls hide adjacent areas.
4. In integration, bind the player through `set_player_target`, log `player_room_changed`, and walk each threshold. Verify transitions and empty ID outside; a freed/unbound actor clears its room on the next tick.
5. Query library stalking records and route between opposite ends of the school. Inspect that all returned segments go through doors/corners. Invalid/outside/wall endpoints must return an empty path. Visibility filtering remains the Monster owner's responsibility.

Created files: `scripts/school/school_foundation.gd`, `scenes/school_foundation.tscn`, `tests/school_foundation_test.gd`, and this handoff. Godot may additionally generate `.uid` sidecars. School progress/backlog notes are updated in the documentation package. Main scene, project settings, imported assets, Player files, and Monster behavior are not modified by this slice.
