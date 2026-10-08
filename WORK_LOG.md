# Work Log

This log records the school-model and Godot-preview work completed with the user. It distinguishes visual blockout work from gameplay behavior that still needs implementation.

## Earlier project and school-model sessions

- Set up the Godot project as an initially empty project, ready for later game work.
- Reviewed the game design documents and school map references, using `map_image` as the primary visual target and `MAP_RECREATION` for additional layout detail.
- Built the school blockout in Blender and organized rooms as separate objects, with each room's walls parented to its floor so the user could reformat rooms independently.
- Updated room labels and corrected the Art Room/Cafeteria naming and layout; established four walls per room and exterior school bounds.
- Added the requested room doors, shared doors, lobby-to-outside entrance, Main Office/Lobby connection, exterior openings, headers, and swing markers. Adjusted door clearances where openings clipped adjacent rooms or opened beyond the school bounds.
- Added the auditorium-adjacent storage closet, removed Classroom F, named the remaining classrooms, and completed the east and north exterior walls.
- Scaled the school/player relationship and added roofs over interior areas. Made the Auditorium, Lobby, Gym, Cafeteria, and Library suitable for double doors, with swing arcs and single-door markers.
- Added rectangular window gaps for the requested room walls, small transom openings above single-door headers, and narrow clerestory openings on the north and east exterior walls. These are wall gaps; no glass panes were created.
- Exported the school to Godot and created a capsule-based third-person preview with WASD movement, mouse camera orbit, and generated collision from wall/floor/roof meshes. Addressed the reported difficulty crossing floor ledges and adjusted the model/player scale so adjacent rooms are less visible over the walls.

## Locker Room hallway door

- Added a single door opening for the Locker Room. The first opening was on the north wall, which the user identified as leading out of bounds.
- Restored the north wall and moved the opening to the Locker Room east wall, facing the interior corridor. Added a swing marker and a wall header.
- Removed the small transom gap above this door when requested.
- Marked the door in Blender custom properties and GLB extras as one-way, operable from the Locker Room side. This is authoring metadata and a visual blockout opening; Godot does not yet implement door interaction or one-way access rules.

## Godot handoff and Git

- Kept the capsule and third-person camera in the separate packed scene `scenes/player_placeholder.tscn`; the school preview instances that scene. The existing `scripts/player_system.gd` remains separate and unchanged.
- Set `scenes/school_blockout_preview.tscn` as the project's run/main scene so F5 opens the school with the capsule and camera reference. The preview loads `assets/school_blockout.glb`, generates collision, and places the capsule at the Nurse Office.
- Updated `GODOT_SCHOOL_PREVIEW.md` with the main-scene, capsule, and camera reference details.
- Created and pushed branch `feature/locker-room-one-way-door`. Commits: `114794a` (school blockout, preview, one-way Locker Room door) and `41383a6` (main-scene assignment and preview note).
- Godot MCP confirmed the configured main scene and launched the project. This confirms the preview starts; it does not verify gameplay door behavior.
- On 2026-10-07, scaled the player instance in `scenes/school_blockout_preview.tscn` to 0.8 for the school blockout. Left `scenes/player_placeholder.tscn` and its movement/camera values unchanged; reloaded and ran the preview.
- On 2026-10-07, shortened the school preview instance's camera distance to 3.5 m (2.8 m at its 0.8 scale), leaving the reusable player scene unchanged; reloaded and ran the preview.
- On 2026-10-07, expanded the Auditorium 4 m north in Blender. Kept the south entrance fixed, extended the floor and east/west walls, moved the north wall, added matching roof/ceiling coverage, and recentered the room label. Re-exported the GLB, reimported it in Godot, and launched the preview.

## Current handoff

- Blender source: `assets.blend`.
- Godot model export: `assets/school_blockout.glb`.
- Main scene: `scenes/school_blockout_preview.tscn`.
- Reusable capsule/camera scene: `scenes/player_placeholder.tscn`.
- Placeholder movement/camera script: `scenes/player_placeholder.gd`.
- Existing PlayerSystem script: `scripts/player_system.gd` (separate; unchanged during this work).
- Gameplay systems remain follow-up work under the owner boundaries and open decisions in `After-School-AI-GDD/docs/AGENTS.md` and the related design docs.

## Monster searchlight and Bell preview (2026-10-07)

- Created `scenes/monster_placeholder.tscn` and its script with a dark 3 m capsule and an opaque yellow triangular search cone. The cone is a visual line-of-sight aid; it does not perform occlusion or detection checks.
- Shortened the search cone to a 6 m forward distance and 2.25 m half-width, preserving its original angle.
- Halved the search cone again to a 3 m forward distance and 1.125 m half-width, preserving the same angle.
- Reduced its size by 75% to a 0.75 m forward distance and 0.28125 m half-width after the cone still covered too much of the preview.
- Restored the regular 3 m forward distance and 1.125 m half-width after fixing the stale running preview.
- Added the stationary monster to the school preview near the Lobby and oriented its cone toward the player start. It has no collision, movement, capture, or player-reset behavior, so contact has no effect.
- Bound **Z** in the preview scene to toggle a visible Bell debug status and red preview background/ambient/key light. This does not implement the authoritative School Bell timer, safe-room selection, or cross-system state.
- Reversed the generated cone triangle winding after Godot mesh validation identified it; the cone no longer appears in the validation findings. The validator still reports pre-existing zero-area UV warnings on room-label meshes.
- Verified the preview runs and the Z toggle switches between OFF/normal and ON/red states.

## Monster hallway patrol (2026-10-07)

- Changed the monster placeholder into a colliding `CharacterBody3D` and added a slow, reversible patrol along a short hallway-side route. Patrol speed and span remain provisional tuning values.
- Moved its preview spawn from the Lobby entrance side toward the Classroom D connection. Patrol remains preview-only; room/door pathfinding, Bell chase, noise response, and capture await School/Player interfaces.
- Added visible-cone and wall-ray checks to enter a short chase, with a configurable loss-of-sight grace period. The monster returns to its patrol when sight is lost; chase does not capture or reset the player.

## Movement speed tuning (2026-10-07)

- Lowered player walk/sprint speeds to provisional 3.5/5.5 m/s. Shift selects sprint speed.
- Lowered monster patrol/chase speeds to provisional 0.5/4.5 m/s, keeping short chase faster than walking and slower than sprint.

## Bell chase speed (2026-10-07)

- Added a preview Bell chase mode at a provisional 6.5 m/s, faster than the current 5.5 m/s player sprint.
- The preview Z toggle now enables/disables the Bell chase along with its red lighting/status. The monster moves toward the player with collision response; it does not pathfind, obey safe-room rules, capture, or reset the player.
- Added the provisional speed and preview limitations to `GODOT_SCHOOL_PREVIEW.md` and Evan's progress handoff.

## Monster Bell pathfinding (2026-10-07)

- Added runtime navigation-mesh baking from the school's generated wall/floor collision geometry. Bell pursuit refreshes its target during movement and follows the path instead of moving directly through walls.
- Added provisional clearance settings and dynamically narrows/lowers the monster capsule and visual in tight doorway gaps.
- The blockout has no authoritative door-state or safe-room data; pathfinding currently uses its modeled doorway gaps. Closed/locked door behavior awaits School's live door-state integration. No capture behavior was added.
- Live Godot check: navigation baked 325 polygons and produced a 7-point route from the Lobby-side monster spawn to the Nurse Office player start. The preview Z toggle entered `BELL_CHASE` at 6.5 m/s.

## Camera-follow hallway spawn (2026-10-07)

- Added a temporary green spawn panel that tracks a candidate point 4 m behind the player camera. It only becomes a candidate when the point stays behind the camera, is within 0.8 m of the navigation surface, is outside all excluded room/outside floor bounds, and remains within 8 m of a known hallway spawn zone.
- The moving point joins the hallway candidates, retaining the existing 75% hallway-first relocation preference. If it cannot find a safe hallway point, it is hidden and skipped.
- Verified in the live Godot preview that the moving point becomes valid behind the camera in the Lobby and remains on the hallway navigation surface. Godot reported no editor errors.

## Automatic preview doors and monster noise (2026-10-07)

- Added runtime door panels to the 24 unique modeled doorway headers. Wide openings use double leaves; narrower openings use one leaf. Panels block the doorway and open once over a provisional 1.8 seconds when the player approaches within 1.35 m; they stay open afterward.
- Kept the Locker Room to hallway door one-way: the player must approach from the Locker Room side to open it.
- Opening a door emits one preview noise event at 0.7 strength. The monster has a 70% response chance: within a provisional 10 m radius it turns and walks toward the sound for up to 6 seconds; farther away it tries spawn panels nearest the door first. Relocation continues to require an off-camera destination and valid navigation point, and is blocked during Bell/chase.
- Added tunable export values for investigation radius/duration and opening duration/trigger distance. The preview door noise probability and strength are the user's requested 70%; investigation range/duration are temporary values pending tuning.
- Godot headless editor import and preview launch completed with no script/navigation errors. Godot printed environment warnings because its user log directory and Windows certificate store are unavailable in this sandbox.
