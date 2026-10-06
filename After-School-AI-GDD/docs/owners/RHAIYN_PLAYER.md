# Rhaiyn — Player System Implementation Brief

## Scope and authority

Own player locomotion, stamina, horizontal third-person camera, interaction requests/prompts, noise event requests for player actions, minimap/objective/HUD, capture presentation, and player-side respawn flow. Follow `AGENTS.md`, `CONTRACTS.md`, and `GAME_SPEC.md`. Do not mutate School progression or implement Monster AI.

## Required behavior

1. Start player at School's Nurse Office spawn. Third-person camera supports horizontal rotation and avoids clipping through geometry. Camera distance/sensitivity/pitch details remain open.
2. Walking is quiet; sprinting is loud and consumes stamina. Exact speeds, capacity, drain, regeneration, and exhaustion behavior remain open tuning values.
3. Interaction selects a target and calls School's public interaction request. Player does not directly open doors, collect items, advance objectives, or trigger exit success.
4. Successful door opening/item collection produce one loud event via the authoritative interaction path. Avoid duplicate event emission from Player and School.
5. Top-left minimap displays map/rooms, player position, item markers as intended, and current objective. It must never show the monster, a monster marker, or monster-derived hint/location data.
6. HUD includes objective, interaction prompt, stamina feedback, and Bell/safe-room cue using School public state. The style and exact icons are open.
7. On capture request, disable player control, show jumpscare, then wait for School checkpoint restoration before repositioning/re-enabling control. Prevent duplicate deaths during presentation/reset.
8. Resume at most recent collected-item checkpoint. If no belongings collected, fallback is Nurse Office; key persistence at this stage is open.

## Integration expectations

- Consume objective/item marker/Bell/checkpoint events from School and capture requests from Monster.
- Provide player world position/current room and noise events per `CONTRACTS.md`.
- Do not reach into Monster scene to get location or into School internals to mutate data.
- Coordinate speed units with Evan so short chase is a little faster than walk and Bell chase a little faster than sprint.
- Inspect existing input mappings, scene layout, renderer, and UI style before adding anything.

## Acceptance checks

- Player starts at Nurse Office; horizontal camera rotation works and remains third-person without wall clipping.
- Walk emits quiet classification, sprint emits loud classification and stamina changes; no frame-by-frame noise spam.
- Stamina values are configurable and exhaustion behavior is documented as provisional or agreed.
- Interaction prompt/request works through public School API; player cannot bypass lock/objective validation.
- HUD/minimap stay at top-left and show current objective and intended item locations.
- Monster location is never rendered or consumed by minimap/HUD.
- Bell transition updates objective/safe-room cue from School snapshot.
- Capture disables input once, presents jumpscare, restores School checkpoint before Player control resumes.
- After death, player returns to the last collected belonging checkpoint; before first item, fallback is Nurse Office pending key decision.

## First recommended slice

Inspect actual project conventions, then implement basic third-person walk/camera and an interaction request against a stub/test target. Keep movement and stamina numbers exported/configurable until tuning is approved. Update Rhaiyn's progress section with controls and manual verification steps.
