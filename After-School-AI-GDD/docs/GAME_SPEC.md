# Game Design and Implementation Specification

## 1. Game summary

**Title:** *After School*  
**Genre:** Third-person school horror / survival exploration  
**Engine:** Godot 4.x; exact minor version **OPEN**  
**Core loop:** Explore a dark school, locate keys, collect six belongings in their designated rooms, survive stalking and Bell chases, then reach the final exit.

The player wakes in the Nurse Office after oversleeping while sick. Their first objective is to find keys in the Main Office. After obtaining them, they collect, in the specified order: Weight (Locker Room), Book (Library), Brush (Art Room), Lab Coat (Lab Room), Ruler (Classroom), Snack (Cafeteria). Once all six belongings are collected, the final objective is to escape through the exit.

## 2. Design principles

1. **Readable urgency:** normal stalking uses dark blue ambient tones and muted yellow school lights; Bell pursuit switches the school to red, with active safe rooms visibly warm/white/yellow.
2. **Sound has risk:** walking is quiet; sprinting, opening a door, and picking up an item are loud.
3. **Doors change the map permanently:** player-opened doors stay open, expanding both player and monster routes. The monster cannot operate doors.
4. **Safe rooms are temporary:** only rooms actively selected and lit as safe during a Bell protect the player.
5. **Death rewinds to collected progress:** jumpscare then restore player and world to the checkpoint associated with the last collected belonging.
6. **The minimap helps objectives, not threat tracking:** show map/rooms, designated item markers, player, and current objective; never show monster position.

## 3. Player and camera

- Third-person player controller with walk and sprint.
- Sprint consumes stamina. Exact walk/run speeds, stamina capacity, drain, regeneration, and exhaustion behavior: **OPEN**.
- Camera may rotate horizontally around the player. Vertical camera behavior, distance, sensitivity, pitch limits, and collision handling: **OPEN** except that the view must remain third-person and avoid clipping through walls.
- Walking emits `QUIET`; sprinting emits `LOUD` noise events.
- Interactions use a consistent in-world prompt/input. Exact input bindings and interaction reach: **OPEN**.

## 4. Objectives and progression

| Order | Objective | Location | Progress effect |
|---:|---|---|---|
| 0 | Wake in Nurse Office; find keys | Main Office | Enables opening locked doors according to the lock layout |
| 1 | Collect Weight | Locker Room | Save new item checkpoint; advance Bell duration progression |
| 2 | Collect Book | Library | Save new item checkpoint; advance Bell duration progression |
| 3 | Collect Brush | Art Room | Save new item checkpoint; advance Bell duration progression |
| 4 | Collect Lab Coat | Lab Room | Save new item checkpoint; advance Bell duration progression |
| 5 | Collect Ruler | Classroom | Save new item checkpoint; advance Bell duration progression |
| 6 | Collect Snack | Cafeteria | Save new item checkpoint; unlock final exit objective and indefinite final Bell behavior |
| 7 | Escape | Final exit | Win condition |

The six belongings are ordered as listed. The conversation does not define whether the player may collect out of order; implement the HUD objective sequence as listed and leave out-of-order pickup handling **OPEN** unless the team confirms. Key checkpoint treatment is **OPEN**; the confirmed checkpoint rule names collected items.

The minimap is top-left and shows current objective plus item locations in their specified rooms. It must not disclose the monster's location. Whether uncollected items are always pinpointed or only current/known objectives are pinpointed should match the intended marker design; exact marker appearance is **OPEN**.

## 5. Doors, keys, and rooms

- Doors start closed. The necessary route from Nurse Office toward Main Office must be traversable before keys; exact door openings and which doors are locked remain to be assigned on the transcribed floorplan (**OPEN; do not make the start inaccessible**).
- Keys are found in Main Office and enable the player to open locked doors.
- Door opening is loud and doors never close after opening.
- The monster cannot open, close, unlock, or teleport through a closed door. It can navigate through rooms and open doorways that are already open.
- The supplied hand-drawn floorplan is transcribed in [MAP_RECREATION.md](MAP_RECREATION.md). Its relative placements and connections are the level-design source of truth; exact scale, wall thickness, room dimensions, and ambiguous door openings remain open for blockout. Preserve the shown arrangement rather than redesigning it.

## 6. Noise and monster response

| Player action | Noise class | Confirmed response |
|---|---|---|
| Walk | Quiet | Low chance to influence a stalking relocation; exact chance **OPEN** |
| Sprint | Loud | Higher chance to influence relocation; if nearby, monster turns attention toward sound |
| Open door | Loud | Higher chance to influence relocation; if nearby, monster turns attention toward sound |
| Pick up item | Loud | Higher chance to influence relocation; if nearby, monster turns attention toward sound |

The audio system is intentionally basic: events communicate footsteps, door opening, pickup, Bell, ambience, and jumpscare. Exact assets, volume curves, sound radii, and random probabilities are **OPEN**. Noise does not guarantee teleportation. Outside Bell, a loud sound may cause relocation or orientation/investigation; if the player is in the monster's POV, it can enter short chase.

## 7. Monster behavior state machine

```text
PATROL / STALK
   ├─ nearby sound ─> INVESTIGATE / TURN TOWARD SOUND
   ├─ player enters POV ─> SHORT CHASE
   ├─ player enters attack proximity ─> CAPTURE
   └─ Bell begins ─> BELL CHASE

INVESTIGATE ── loses stimulus / timeout (OPEN) ─> PATROL
SHORT CHASE ── loses LOS or escapes (threshold OPEN) ─> PATROL / INVESTIGATE
Any non-final state ── Bell begins ─> BELL CHASE
BELL CHASE ── active safe room reached OR timed Bell ends ─> PATROL
Final Bell ── remains BELL CHASE until escape or capture
```

- Patrol is slow and primarily uses school halls/rooms via valid open routes.
- Offscreen relocations are fairly common. Relocate only when the monster is offscreen; if a candidate would be visible, shift to a different valid candidate. The monster must never visibly pop from one location to another.
- Flicker is less frequent: approximately 10% chance when the player spots the monster, and only sometimes conceals a relocation. Treat 10% as an initial target, not a fully specified sampling interval; exact event cooldown is **OPEN**.
- Outside Bell, monster may kill the player. A nearby loud event draws its attention; seeing the player in its POV triggers short chase. Exact perception, kill distance, wind-up, cooldown, and chase termination are **OPEN**.
- Short chase is a little faster than player walking speed. Do not encode a ratio until movement tuning is approved; expose it as a tuning property.
- During Bell, monster physically pathfinds toward player, takes valid shortcuts through open doorways, and moves a little faster than player sprint. It cannot teleport during Bell chase.
- **Capture resolution:** request player jumpscare/death; player/checkpoint service owns the reset. Monster must not directly reposition the player or restore world state.

## 8. Bell, lighting, safe rooms

- Bell activates a full pursuit state and red school lighting.
- Bell begins at 10 seconds. Its duration increases by 2 seconds with progression until the final escape phase. The exact progression event count and whether the initial 10-second Bell is first scheduled before or after the first collectible are **OPEN**.
- During a Bell, random eligible rooms are lit as active safe rooms. The monster cannot enter an active safe room. Protection is conditional on both active Bell phase and that room's active-safe status; merely entering any lit room does not protect the player.
- The player must reach an active safe room before the Bell timer ends. If its door is open, they enter directly. If closed, opening it is loud, then they enter. The monster still cannot operate that door.
- Safe-room count, selection algorithm, eligibility, whether rooms remain safe for the entire Bell, and what happens if the player is already inside a selected room are **OPEN**.
- Final escape Bell plays indefinitely until player reaches the exit. Monster remains in full chase and cannot teleport; successful exit ends the game. Capture still causes checkpoint restart.
- Normal palette: dark blue-ish ambient with muted yellow-ish school lights. Bell palette: red school lighting. Active safe rooms retain a distinguishable warm light. Do not implement a solid red screen overlay that obscures visibility.
- Transition duration/flicker/blackout, exact color/light values, and audio timing are **OPEN**. Red/normal lighting, safe-room selection, Bell audio, monster mode, and HUD objective must all respond to the same authoritative Bell state.

## 9. Checkpoints, death, and reset

- Collecting each of the six belongings saves the newest checkpoint.
- On capture: play jumpscare, then restore player and world to the last belonging checkpoint.
- Restore the world state associated with that checkpoint (not the state at moment of death): player spawn/position for that checkpoint; collected belonging flags/progression; opened doors/other persistent room state; and the phase/progression values needed to make the checkpoint internally consistent.
- Exact snapshot schema, treatment of keys (including whether retained if not represented in checkpoint), monster state on restore, and whether a Bell timer is reset or resumed: **OPEN**. Team should choose explicitly before checkpoint implementation. Until decided, do not destroy the saved checkpoint on death.
- Before the first belonging checkpoint, the spawn Nurse Office is the fallback checkpoint; the interaction between keys and this fallback is **OPEN**.

## 10. Victory and failure

- Victory: all six belongings collected and player reaches the final exit during the final escape objective.
- Failure: monster catches player outside or during Bell. Show jumpscare and restore checkpoint.
- Menus, pause, save-to-disk, multiple endings, and full game-over are not specified and must not be added without approval.

## 11. Cross-system ownership summary

See [CONTRACTS.md](CONTRACTS.md) for exact names and payloads.

- **Rhaiyn / Player:** movement/camera/stamina, emitting player noise events, interaction requests, item pickup request, minimap/HUD, jumpscare and checkpoint respawn presentation.
- **Zion / School:** rooms/nav geometry, door/keys/item/exit authority, Bell clock, active safe-room set, lighting modes, canonical checkpoint snapshot of world progression.
- **Evan / Monster:** patrol/perception/investigation/chases, offscreen reposition selection, path-follow behavior, safe-room exclusion, capture request.

## 12. Tuning table

| Setting | Baseline | Status / owner for tuning |
|---|---:|---|
| Initial Bell duration | 10 seconds | Confirmed; Zion implements |
| Bell duration progression | +2 seconds per progression step | Confirmed increment; exact trigger/count open; Zion |
| Final escape Bell duration | Indefinite until exit | Confirmed; Zion |
| Flicker chance when spotted | About 10% | Approximate target; event interval open; Evan |
| Quiet action | Walking | Confirmed; Rhaiyn emits |
| Loud actions | Sprint, opening door, item pickup | Confirmed; Rhaiyn emits; door pickup authority emits for world interactions |
| Short chase speed | Slightly above walking | Relative target confirmed; exact speed open; Evan/Rhaiyn coordination |
| Bell chase speed | Slightly above sprint | Relative target confirmed; exact speed open; Evan/Rhaiyn coordination |
| Walk/run speed; stamina | Unset | Open; Rhaiyn |
| Sound radii/probabilities | Unset | Open; joint tuning |
| Patrol/relocation interval and range | “Fairly common” | Qualitative target; open; Evan |
| POV range/FOV/attack range | Unset | Open; Evan |
| Normal chase escape thresholds | Unset | Open; Evan |
| Bell cadence/first trigger | Unset | Open; Zion + team |
| Active safe-room count/selection | Random rooms; count unset | Open; Zion |
| Map/door topology | Not supplied here | Open; Zion/team |
| Camera distance/sensitivity/pitch | Unset | Open; Rhaiyn |

All tuning values should be exported/configurable and centralized rather than scattered as literals. A temporary playable default is acceptable only when marked provisional in progress notes and not treated as a settled design decision.

## 13. Implementation priorities

1. Agree/publish floorplan and map connectivity; create room/door/item IDs.
2. Freeze data contracts and a minimal main-scene integration approach.
3. Build traversal foundation: rooms, door state/key gating, player movement/camera, interaction.
4. Add item objective sequence and checkpoint snapshot/restore.
5. Add Monster patrol, perception, and non-Bell response.
6. Add Bell manager, safe rooms, red lighting, pathfinding chase, and transitions.
7. Add minimap/objective UI, audio events, jumpscare, final exit and victory.
8. Tune values through play; record decisions and update acceptance checks.

Priority may shift to establish a playable vertical slice, but contract changes and owner boundaries remain coordinated.
