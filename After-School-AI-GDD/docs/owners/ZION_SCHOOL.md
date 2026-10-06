# Zion — School System Implementation Brief

## Scope and authority

Own the school world and progression authority: room/map definitions, door/key logic, item placement and objective sequence, Bell clock, active safe-room selection, lighting state, canonical world checkpoint snapshot/restore, and final exit validation. Follow `AGENTS.md`, `CONTRACTS.md`, and `GAME_SPEC.md`. Do not edit Player locomotion/HUD or Monster AI.

## Required behavior

1. Build the supplied floorplan from `docs/MAP_RECREATION.md` and the user's original map image (attach that image to the AI task), with stable room, door, item, and exit IDs. Preserve room placement and adjacency; flag ambiguous openings instead of redesigning the layout.
2. Player begins in Nurse Office; first target is keys in Main Office. Ensure an intentional traversable route exists before keys; lock exceptions must follow the approved map.
3. Doors start closed, locked doors require keys, successful opening is loud, and doors remain open permanently. Monster cannot operate doors. Expose state/connectivity to Monster.
4. Provide six collectible placements in their specified rooms/order and update current objective. Each belonging pickup commits a new item checkpoint.
5. Bell starts at 10 seconds and grows by 2 seconds per agreed progression step; final escape Bell is indefinite. Bell schedule and exact progression mapping are open.
6. On Bell, select random eligible active safe rooms and publish room IDs consistently with Bell state. Only those active rooms protect the player; ordinary lit rooms do not. Monster exclusion is communicated to Evan.
7. Drive red Bell lighting and dark-blue/muted-yellow normal school lighting. Active safe rooms retain distinguishable warm lighting. HUD, Monster, and lighting consume one authoritative School state.
8. At final item, set escape objective and permit victory only at the exit. Final Bell ends only on exit or capture/reset behavior as specified.
9. Own the saved world checkpoint snapshot. Capture restore must return doors, items/progression, Bell/safe-room state, and other included world state to the last belonging checkpoint. Exact snapshot fields and key treatment remain an explicit team decision.

## Integration expectations

- Implement public methods/signals per `CONTRACTS.md`; use stable IDs and typed data consistent with project conventions.
- Commit world interaction state before publishing success signals. Door/item loud noise should emit once at successful School interaction.
- Expose minimap objective/item marker data but never monster position.
- Do not edit shared root scene/project settings unless selected as integration owner.
- The map topology, exact lock plan, safe-room count/eligibility, Bell cadence, transition timing, and checkpoint details are open; do not silently invent them.

## Acceptance checks

- Player can start in Nurse Office and reach Main Office key objective through valid initial route.
- Locked door requires keys; successful open emits one loud event and permanently opens it.
- Six belongings are mapped to the correct rooms, update objective state, and save the latest checkpoint.
- After each item, saved world snapshot matches that moment; restore returns relevant doors/items/progression and player checkpoint coherently.
- Bell state and timer follow agreed 10s/+2s/final indefinite rules; Bell snapshot synchronizes safe rooms, lighting, Monster, and HUD.
- Random safe-room selection is repeatable/testable through a controlled random source where available; only active selected rooms are protected.
- Final exit is unavailable until all six belongings are collected; exit ends final Bell and emits victory.
- Item/objective markers never reveal the monster.

## First recommended slice

Inspect the project and translate the supplied floorplan into stable room/door IDs and a traversable graybox. Preserve relative layout, mark uncertain openings for review, then wire a single testable door interaction. Do not implement Bell cadence or checkpoint field assumptions until open decisions are resolved or clearly isolated as provisional settings.
