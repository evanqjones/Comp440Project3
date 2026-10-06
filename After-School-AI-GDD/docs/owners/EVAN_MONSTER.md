# Evan — Monster System Implementation Brief

## Scope and authority

Own the monster's behavior and movement: patrol/stalking, offscreen reposition selection, perception/noise response, investigation, short chase, Bell chase, navigation behavior, active-safe-room exclusion, and capture request. Follow `AGENTS.md`, `CONTRACTS.md`, and `GAME_SPEC.md`. Do not edit Player or School-owned code to make the monster work.

## Required behavior

1. **PATROL/STALK:** move slowly through valid rooms/halls. Relocation is fairly common outside Bell and only allowed when not visible to the player.
2. **Relocation visibility:** before committing a candidate location, test whether the monster would be visible. If so, reject it and choose another valid location. Never visibly teleport.
3. **Flicker:** when spotted, use approximately 10% chance as initial tuning target for a flicker event; flicker is less frequent and only sometimes conceals a relocation. Add an event cooldown/tuning setting; its exact interval is open.
4. **NOISE/INVESTIGATE:** quiet walking noise has low chance to influence stalking relocation. Loud sprint/door/item events have higher chance. If a loud source is nearby, turn attention toward it and investigate. Do not make every loud event cause teleport.
5. **SHORT CHASE:** player inside monster POV can trigger chase outside Bell. Monster is a little faster than walking speed. It can kill outside Bell. Exact FOV, attack distance, windup, chase duration and escape thresholds are open tuning values.
6. **BELL CHASE:** Bell state overrides all stalking behavior. Physically pathfind toward live player position, use only traversable rooms/open doors, move a little faster than sprint, avoid active safe-room interiors, and never teleport.
7. **CAPTURE:** emit one `capture_requested` event. Player owns jumpscare/reset; School owns checkpoint/world restoration. Never reposition player or mutate doors/progression.

## Integration expectations

- Consume `NoiseEvent`, Bell snapshots, safe-room IDs, player position, door-open notifications, and room/nav queries using `CONTRACTS.md`.
- Request navigation data from Zion. Do not assume a floorplan, navmesh, room dimensions, monster model, or asset path before inspecting the actual project.
- Keep chase speed and perception/reposition tuning configurable. Coordinate units with Rhaiyn. No exact numerical speed ratios beyond qualitative “a little faster” have been approved.
- Communicate monster state for debugging/presentation if useful, but never expose position to HUD/minimap.

## Suggested internal states

`PATROL`, `INVESTIGATE`, `SHORT_CHASE`, `BELL_CHASE`, `CAPTURE_PENDING`. Bell start forces `BELL_CHASE`; capture is guarded against duplicate signals. Timed Bell end returns to stalking only when School reports Bell inactive; final Bell remains active until escape/capture.

## Acceptance checks

- Monster cannot cross a closed door and can traverse an opened doorway.
- Outside Bell, visible monster never teleports; an offscreen valid relocation occurs only when not visible.
- Loud nearby sound draws attention; noise can influence candidate selection probabilistically; quiet events are less influential.
- POV sight can trigger short chase and monster can capture player outside Bell.
- Short chase speed target is above walking and below sprint/Bell chase intent, pending tuning.
- Bell transition immediately overrides stalking; monster pursues by path, slightly above sprint, and never teleports.
- Active safe rooms are excluded while active; ordinary/inactive rooms do not protect player.
- Capture request fires once; Monster does not reset player/world.
- No monster marker or location data enters minimap/HUD APIs.

## First recommended slice

Inspect project and agree with Zion on room/door/nav data. Implement a stationary/state-machine skeleton receiving Bell/noise/player inputs before adding relocation and pathfinding. Mark all unresolved behavior settings provisional and update Evan's progress section.
