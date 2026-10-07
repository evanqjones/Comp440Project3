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

## Current handoff

- Blender source: `assets.blend`.
- Godot model export: `assets/school_blockout.glb`.
- Main scene: `scenes/school_blockout_preview.tscn`.
- Reusable capsule/camera scene: `scenes/player_placeholder.tscn`.
- Placeholder movement/camera script: `scenes/player_placeholder.gd`.
- Existing PlayerSystem script: `scripts/player_system.gd` (separate; unchanged during this work).
- Gameplay systems remain follow-up work under the owner boundaries and open decisions in `After-School-AI-GDD/docs/AGENTS.md` and the related design docs.
