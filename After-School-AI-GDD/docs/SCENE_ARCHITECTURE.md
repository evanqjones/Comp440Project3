# Proposed Godot Scene Architecture

This is a proposed logical structure, not a statement about the current repository. Inspect the actual project first and map the responsibilities onto its conventions. The exact root scene, autoload setup, renderer, and asset paths remain open.

## Logical runtime tree

```text
GameRoot (integration-owned; final name TBD)
├── School (Zion)
│   ├── Rooms / Hallways / Doorways
│   ├── Doors and interactable objects
│   ├── Item placements and final exit
│   ├── SchoolState (progression, Bell, checkpoints)
│   ├── LightingController
│   └── NavigationRegion3D / room graph
├── Monster (Evan)
│   ├── VisualRoot
│   ├── CollisionShape3D
│   ├── NavigationAgent3D (if compatible with chosen map)
│   └── MonsterController
├── Player (Rhaiyn)
│   ├── CharacterBody3D
│   ├── CameraPivot / Camera3D
│   ├── InteractionProbe
│   └── PlayerController
└── HUD (Rhaiyn)
    ├── Minimap (top-left; no monster marker)
    ├── ObjectiveText
    ├── InteractionPrompt
    ├── StaminaDisplay
    └── Bell / capture presentation
```

## Suggested file ownership

```text
systems/
  school/       # Zion: map, room/door/item data, Bell and checkpoint authority
  monster/      # Evan: monster scene, controller, perception, state machine
  player/       # Rhaiyn: controller, camera, interaction client, HUD/minimap
  shared/       # only after team agrees on ownership and contracts
```

Do not create this exact tree if the project already has an established layout. Keep each system's scenes/scripts/resources together under the existing convention.

## Scene responsibilities

- **Game root:** instantiates systems and wires public signals. Integration owner must be explicitly chosen; no teammate should silently edit a shared main scene.
- **School:** owns authoritative room IDs, interaction validation, door/collectible state, objective progression, Bell timer/safe-room selection, lighting mode, checkpoint snapshot and exit validation.
- **Monster:** owns state machine and movement. Receives player target and School updates through contract. It cannot directly change doors, objectives, lighting, checkpoints, or Player transform.
- **Player:** owns locomotion, stamina, camera and HUD. Sends interaction/noise requests; does not mutate School state directly.

## Navigation guidance

Use Godot navigation or an explicit room/door graph based on the approved level geometry. Which approach is best depends on the final map and is **OPEN**. Whatever approach is selected must represent opened-door connectivity, block closed doors, permit valid room traversal, allow Bell pursuit path updates, and exclude active safe rooms. A visual teleport is forbidden; stalking relocation must be performed only offscreen and outside Bell.

## Scene integration checklist

- All room, door, item, objective, and safe-room IDs are stable and documented.
- System instances communicate only through public contracts.
- Signal connections happen once and are disconnected/rebound correctly on reload.
- Player starts at Nurse Office spawn.
- Monster never appears on minimap.
- A checkpoint restore rebuilds or restores School state before Player controls resume.
- A Bell transition updates Monster, red lighting, safe rooms, audio, and HUD from the same authoritative snapshot.
