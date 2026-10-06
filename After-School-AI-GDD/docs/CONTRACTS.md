# System Contracts

These are the shared boundaries among Player (Rhaiyn), School (Zion), and Monster (Evan). Names below are canonical design names; map them to existing code conventions during integration. Do not change a signature unilaterally. Implement cross-system communication with typed signals/public methods, not scene-tree path reach-through.

## 1. Ownership

| Data/behavior | Authority | Consumers |
|---|---|---|
| Player movement, stamina, camera, current transform | Player | Monster, School |
| Noise event source/class/world position | Player or interacting world actor; normalized through shared event | Monster |
| Room IDs, adjacency/nav geometry, door state, keys/items/exit | School | Player, Monster, HUD |
| Bell active/final state, remaining time, safe-room IDs | School | Player HUD, Monster |
| Monster state and transform | Monster | Presentation only; never minimap |
| Checkpoint snapshot of progression/world | School owns canonical world snapshot; Player owns respawn flow | Player, School |
| Capture/jumpscare request | Monster emits request; Player resolves death/reset | Player, School |

## 2. Shared identifiers and data

Use stable `StringName` or project-standard typed IDs. IDs are authored by School and shared before use. Required logical values:

```gdscript
enum NoiseLevel { QUIET, LOUD }
enum LightingMode { NORMAL, BELL }

class_name NoiseEvent
var source_position: Vector3
var level: NoiseLevel
var source_id: StringName

class_name BellSnapshot
var active: bool
var final_escape: bool
var remaining_seconds: float
var progression_index: int
var active_safe_room_ids: Array[StringName]
```

This snippet describes fields, not a requirement to create global class files. Use typed resources/classes consistent with the repository. IDs for rooms/doors/items are owned by School. Checkpoint snapshot must be serializable or safely copied in memory; do not retain node references that become invalid during scene reload.

## 3. Player public surface (Rhaiyn-owned)

Expected public events/methods:

```gdscript
signal noise_emitted(event: NoiseEvent)
signal interaction_requested(target_id: StringName)
signal player_captured(reason: StringName)

func get_world_position() -> Vector3
func get_current_room_id() -> StringName
func set_input_enabled(enabled: bool) -> void
func play_capture_and_respawn(checkpoint_id: StringName) -> void
```

- Movement publishes `QUIET` while walking and `LOUD` while sprinting according to the agreed event policy. Avoid emitting per-frame events; use a cooldown/continuous-noise representation decided jointly and documented in code.
- Opening a door and picking up an item are loud. School-owned actions should emit the event at the authoritative successful interaction point; do not double-emit from Player and School.
- Player asks School to interact; it does not mutate door/item/exit state directly.
- Player HUD consumes objective, item-marker, Bell, and safe-room data from School. It must never request or render monster position.

## 4. School public surface (Zion-owned)

Expected public events/methods:

```gdscript
signal objective_changed(objective_id: StringName, display_text: String)
signal item_collected(item_id: StringName, item_index: int)
signal door_opened(door_id: StringName, room_a: StringName, room_b: StringName)
signal bell_state_changed(snapshot: BellSnapshot)
signal active_safe_rooms_changed(room_ids: Array[StringName])
signal checkpoint_saved(checkpoint_id: StringName)
signal checkpoint_restored(checkpoint_id: StringName)
signal exit_reached()

func request_interaction(target_id: StringName, actor_id: StringName) -> bool
func get_objective_snapshot() -> Dictionary
func get_item_marker_data() -> Array[Dictionary]
func get_door_state(door_id: StringName) -> int
func get_room_id_at(world_position: Vector3) -> StringName
func is_room_active_safe(room_id: StringName) -> bool
func get_bell_snapshot() -> BellSnapshot
func capture_checkpoint(checkpoint_id: StringName) -> void
func restore_checkpoint(checkpoint_id: StringName) -> void
```

Use project-appropriate typed data instead of raw `Dictionary` if existing code supports it. `request_interaction` validates current objective/key/door/item/exit state and returns whether it succeeded. Door opens permanently. It emits exactly one loud noise event on success. The exit only emits `exit_reached` when all six belongings are complete and the final objective is active.

## 5. Monster public surface (Evan-owned)

Expected input/events:

```gdscript
signal capture_requested(reason: StringName)
signal monster_state_changed(state_id: StringName)

func set_player_target(player: Node3D) -> void
func receive_noise(event: NoiseEvent) -> void
func set_bell_state(snapshot: BellSnapshot) -> void
func set_safe_rooms(room_ids: Array[StringName]) -> void
func on_door_opened(door_id: StringName, room_a: StringName, room_b: StringName) -> void
```

The Monster may read player position and approved School navigation/door/safe-room queries. It does not mutate Player or School state. It emits `capture_requested` once per capture and waits for Player to disable control/resolve reset. Bell state overrides other behavior. On final Bell, it remains in Bell chase until the game ends or capture occurs.

## 6. State synchronization and event order

1. School owns the authoritative Bell transition and emits its full snapshot.
2. Monster immediately switches to Bell chase; School selects and publishes safe-room IDs; lighting and HUD update from the same snapshot/events.
3. If random active safe rooms are selected on Bell start, publish the IDs before/with the active Bell snapshot, never a frame later with an unprotected visual promise.
4. School validates interactions and commits door/item/exit changes before emitting success signals.
5. On item success, School updates objective/progression, saves checkpoint snapshot, then publishes item/objective/checkpoint signals in a documented stable order. Exact signal ordering must be finalized in implementation; no consumer may assume the checkpoint event arrives before item event unless documented.
6. On capture: Monster emits once → Player disables input and plays jumpscare → School restores world checkpoint → Player repositions/restores HUD/control after School reports restored.
7. No system may retain stale references across scene rebuild/respawn; use stable IDs and rebind.

## 7. Navigation/door invariant

- Monster navigation only traverses valid room connections and opened doors.
- Closed doors are blockers; Monster cannot request their opening.
- School informs Monster when a door opens and exposes current door/nav state for replanning.
- During Bell chase, Monster pathfinds continuously enough to respond to player movement and door graph changes; exact update frequency is a performance/tuning value.
- Active safe-room interiors are forbidden navigation destinations/regions while active. Safe-room selection is authoritative in School.

## 8. Checkpoint invariant

The saved checkpoint represents the world at the most recently collected belonging. On death, world progression and player position are restored to that snapshot. A new item checkpoint supersedes the previous snapshot only after pickup is committed. Repeated capture during the jumpscare/reset sequence cannot trigger multiple restores. Key behavior and exact checkpoint snapshot fields are listed as open in `GAME_SPEC.md` §9.

## 9. Contract change protocol

1. Propose exact old/new signature, reason, and affected systems in `DECISIONS.md`.
2. Notify every affected owner; update acceptance checks.
3. Get explicit team agreement before implementation.
4. Update this file and all affected owner docs together.
5. Integrate consumers/producers in a coordinated slice. Never keep compatibility shims indefinitely without a decision.
