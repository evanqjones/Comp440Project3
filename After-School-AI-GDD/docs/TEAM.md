# Team Ownership and Integration

## Owners

| Owner | System | Owns | Does not own |
|---|---|---|---|
| **Evan** | Monster System | Patrol/stalking, perception, investigate/short chase/Bell chase, relocation, path behavior, safe-room avoidance, capture request | Player reset, door mutation, Bell clock, lighting, HUD, minimap |
| **Zion** | School System | Floorplan/rooms, doors/keys, item locations/progression, exit, Bell clock, safe-room selection, lighting state, canonical world checkpoint snapshot | Player locomotion/HUD, monster AI decisions |
| **Rhaiyn** | Player System | Movement/sprint/stamina, camera, interaction client, noise requests, minimap/objectives/HUD, capture presentation and respawn flow | Door/item authority, Bell authority, monster state/marker |

## Asset creation

The user owns asset production and may use AI tools for it. Asset creation does not need to be part of the teammates' default coding tasks. Agents should focus on their assigned systems and use available project assets or clearly identified placeholders. The user may explicitly assign an asset-related task when needed. Evan's Monster System ownership is separate from asset production.

## Shared responsibilities

- Agree exact floorplan and room/door connectivity before navigation or minimap implementation is considered complete.
- Agree unresolved values in `GAME_SPEC.md` and record them in `DECISIONS.md`.
- Keep cross-system APIs aligned with `CONTRACTS.md`.
- Choose a named integration owner for root scene/project configuration when the repository is available. **OPEN:** no one is assigned that role in the user brief.

## Handoff rules

- Handoff stable IDs, units, signal timing, and test steps in the relevant owner section of `PROGRESS.md`.
- If an owner needs another system's change, add a TODO/handoff request; do not edit the other owner's files.
- Public contract changes require all affected owners' agreement.
- Asset production is handled by the user, who may use AI tools; it is outside teammates' default coding scope. Exact Godot/project workflow has not been assigned; inspect the repo before adding dependencies.

## Suggested review pairs

Review pairing is **OPEN**. Suggested for coordination only: Evan ↔ Zion for path/door/safe-room behavior; Zion ↔ Rhaiyn for objectives/checkpoints/HUD; Rhaiyn ↔ Evan for noise, perception, and speed tuning. The team should confirm before relying on these as formal review assignments.
