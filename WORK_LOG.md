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

- Added runtime door panels to the 24 unique modeled doorway headers. Wide openings use double leaves; narrower openings use one leaf. Panels block the doorway and open once over a provisional 1.8 seconds when the player approaches within 2.0 m; their collision releases when the opening animation finishes.
- Kept the Locker Room to hallway door one-way: the player must approach from the Locker Room side to open it.
- Opening a door emits one preview noise event at 0.7 strength. The monster has a 70% response chance: within a provisional 10 m radius it turns and walks toward the sound for up to 6 seconds; farther away it tries spawn panels nearest the door first. Relocation continues to require an off-camera destination and valid navigation point, and is blocked during Bell/chase.
- Added tunable export values for investigation radius/duration and opening duration/trigger distance. The preview door noise probability and strength are the user's requested 70%; investigation range/duration are temporary values pending tuning.
- Godot headless editor import and preview launch completed with no script/navigation errors. Godot printed environment warnings because its user log directory and Windows certificate store are unavailable in this sandbox.
- Fixed doorway traversal after the initial mechanic pass: extended the approach distance to 2.0 m and disabled the leaves' collision after they finish opening. A headless CharacterBody movement check crossed a double Auditorium door and a single Classroom A door; it confirmed the Locker Room hallway door stays closed from the hall side and opens/pass-through works from the Locker Room side.

## Door push direction and Locker Room return (2026-10-07)

- Changed the approach threshold to 0.5 m so a door opens when the capsule reaches it. Door leaves now swing away from the player's side in the direction of the push.
- The Locker Room hallway door is the only auto-closing door. It remains open until the player clears the doorway, waits a provisional 1 second, swings shut over 1.8 seconds, then restores collision. It still cannot be opened from the hallway side.
- The GDD says doors never close; this Locker Room-only close behavior follows the user's explicit exception. The hold time is provisional.
- Headless behavior check passed on the Auditorium double door and Classroom A single door: both triggered at 0.35 m, swung away from the player, released collision, and allowed the capsule to cross. The Locker Room door ignored the hallway side, opened from inside, stayed open while occupied, then closed and restored collision after the player passed through.

## Monster approaches distant door noise (2026-10-07)

- After a successful off-camera relocation to the spawn nearest a far door sound, the monster now enters INVESTIGATE and follows its navigation path toward that doorway at a provisional 0.5 m/s.
- Nearby noise uses the same investigation path. Its investigation timer now starts after arrival so a slow approach is not cut short; hallway pacing resumes afterward if the monster had been pacing before the noise.
- Headless behavior check started the monster at a hallway spawn 6.01 m from the Auditorium door. After 120 frames it remained in INVESTIGATE, had moved 0.44 m, and was 5.60 m from the sound.

## Monster traverses open doors (2026-10-07)

- Added a navigation link for every unique school doorway. Links stay disabled while a door is closed, enable after the door finishes opening, and disable again when the Locker Room one-way door closes. Opening a door refreshes an active investigation or Bell chase route.
- Added low-header detection ahead of the monster so it compresses to the existing 1.8 m preview squeeze height before reaching 2.15 m door headers. Investigation movement now uses the same squeeze/collision handling as Bell chase and restores its normal capsule on return to patrol.
- The Locker Room door waits while the monster is investigating or chasing, or physically occupying its threshold, so it does not shut in front of an active crossing.
- Headless CharacterBody check confirmed the monster remained on its side of a closed Auditorium door, then crossed the same doorway after it opened. The navigation map created 24 door links.

## Smaller monster doorway squeeze (2026-10-07)

- Reduced the monster's minimum squeeze width from 30% to 15% and minimum height from 1.8 m to 1.2 m so it can fit more tightly through open doorway gaps.
- Headless CharacterBody check confirmed it stays blocked by the closed Auditorium door, crosses once the door opens, reaches 1.2 m during passage, and restores its 3 m standing height afterward.

## Bell safe-room window lurking preview (2026-10-07)

- Read `GAME_SPEC.md`, `CONTRACTS.md`, `EVAN_MONSTER.md`, and `ZION_SCHOOL.md`. Kept this feature in the Godot preview only because School owns authoritative safe-room selection and lighting; reused the existing Monster `set_safe_rooms(Array[StringName])` contract surface.
- On Z Bell start, the preview randomly chooses exactly three eligible rooms with walkable perimeter routes, excluding the Lobby, adds a warm OmniLight3D to each, and disables open-door navigation links that enter those room bounds. Z off clears the active room list and removes the lights.
- Added purple floor tiles at each walkable hallway-facing window side from the supplied room window layout (seven sites in the current model). Added 38 unmarked outer perimeter waypoints across the rooms; they support a slow 0.35 m/s Bell loop while the player is inside an active safe room.
- Headless preview output reported 7 window tiles and 45 total Bell waypoints. Bell mode chose exactly three rooms. A temporary targeted check placed the player in a selected room and confirmed the monster remained outside its bounds with a lurking destination outside the room; temporary test code and logs were removed.
- This does not replace Zion's authoritative safe-room selection or lighting and does not change the open GDD decisions for the production system.
- Follow-up: excluded the Lobby from the eligible safe-room pool. A headless Bell run confirmed the Lobby was not selected and three other rooms were still selected.

## Player crouch and movement-noise preview (2026-10-07)

- Added a shared typed `NoiseEvent` data class and a Player `noise_emitted` signal. Moving while walking emits QUIET events every 0.8 seconds; running emits LOUD events on the same cadence. Crouching emits no movement noise.
- Ctrl crouches the placeholder capsule, lowers its camera, prevents sprint, and uses a provisional 2.0 m/s speed. Shift sprint remains 5.5 m/s; walking remains 3.5 m/s.
- Wired Player noise to the preview Monster. Nearby quiet events have a 30% chance to make it face the player without moving. Loud events use the existing 70% door-noise response chance and its investigation or off-camera relocation behavior. Bell suppresses both responses.
- Godot 4.7.2 headless editor scan and preview startup completed without GDScript errors. Preview startup created 24 doors and the existing window markers. Godot emitted its environment-only root-certificate and editor-settings warnings; no project script errors appeared.
- Values are provisional preview tuning. No footstep audio clips were added; these events drive gameplay response only.

## Stuck investigation relocation fallback (2026-10-07)

- Added a 15-second no-progress timer during INVESTIGATE. The progress check measures distance to the active sound target, so normal movement toward it resets the timer.
- When stuck, the monster retries the existing spawn relocation path once per second. That path still rejects a move if the monster's current body or destination is visible from the player camera; wall occlusion is accepted. It remains disabled during Bell.
- Godot headless startup is used to check script parsing and preview initialization; the fallback logic is not yet exercised with a dedicated automated test.

## Investigation vision and noise awareness (2026-10-07)

- Moved player visibility checks ahead of the INVESTIGATE branch. If the player is visible in the search cone, investigation now transitions to SHORT_CHASE immediately.
- Nearby quiet walking and loud running events during INVESTIGATE set a short look target toward the sound source. Patrol's 30%/70% response behavior remains unchanged.
- The headless Godot editor scan found no GDScript parse errors.

## Item-room encounter preview (2026-10-07)

- Read the new `After-School-AI-GDD/docs/interactions.docx` encounter notes and added glowing circle markers with floating names for School Keys, Weight, Book, Brush, Lab Coat, Ruler, Snack, and Front Door Key. Press E near a marker to collect it; preview pickups publish a loud noise event.
- Added room-specific Monster preview behavior: guards the Weight and scans, slowly follows/searches the Library and disappears on Book pickup, switches between Art Room positions only while outside camera view, remains still and investigates loud sound in the Lab Room, reduces to a glowing face while shifting positions during the Ruler encounter, and patrols/chases by sight in the Cafeteria. Main Office keys have no special monster encounter. The Front Door Key begins permanent Bell chase and cannot be toggled off with Z.
- The Ruler is assigned to Classroom B per user direction. No authoritative School inventory, objectives, checkpoints, or production item signals were added.
- The current school blockout has no locker/table/shelf hiding cover, actual library maze, or Art Room human figures; the Ruler room also has not been darkened. The Monster behavior is wired for the preview, while those room visuals and props still need level geometry before the navigation/cover tactics can be judged. No runtime verification was run for this slice.

## Science Classroom Lab Coat encounter (2026-10-08)

- Moved the Lab Coat preview item circle to the northwest corner of the Science Classroom. The monster targets its southeast corner and faces east into the wall.
- Walking and running noise events make it slowly turn and sweep its existing search cone toward the player. When the cone ray check sees the player, the existing SHORT_CHASE starts. Crouching emits no movement noise, so it does not provoke this turn.
- After collecting the Lab Coat and exiting the Science Classroom, the monster waits for a valid Science Classroom window-side hallway marker, then relocates there only when both its current body and destination are outside the camera view or occluded. It resumes a short hallway patrol from that window.
- This updates the preview placement from the interactions document's prior Lab Room assignment per the user's instruction. No runtime verification was run for this slice.

## Science/Lab placement correction (2026-10-08)

- Corrected the previous pass: Lab Coat marker is back in the Lab Room northwest corner. Entering the Science Classroom while it remains uncollected queues the monster's southeast-corner wall-facing appearance and its movement-noise/slow-turn/spotlight-chase behavior.
- The scripted appearance still honors the camera visibility rule. When the player exits into the adjacent Lab Room, the monster queues a camera-safe spawn beyond a Science Classroom window and resumes hallway patrol.
- No runtime verification was run for this correction.

## Lab north-window stalk adjustment (2026-10-08)

- Changed the post-transition stalk point to the hallway side of the Lab Room north window. On an off-camera-safe relocation, the monster turns toward the Lab Room and stands still there.
- Paused automatic relocation during the stationary window stalk; Bell behavior can override it.
- Supersedes the prior Science Classroom window/patrol destination note. No runtime verification was run.
- Follow-up fix: if the Lab north-window lurk marker was not generated, the stalk computes the hallway-side target from the Lab floor bounds and snaps it to navigation. The teleport continues to require both current and destination positions to be outside camera view or occluded.

## Lab Coat window response (2026-10-08)

- Lab Coat pickup now makes the monster slide to the left along the hallway from the Lab north-window stalk using the navigation agent. Automatic relocation stays paused while it moves, then resumes from its previous countdown. Pickup before the stalk appears is also handled after the delayed off-camera spawn.
- No runtime verification was run.

## Library book maze preview (2026-10-08)

- Moved the Book circle to the far-left corner from the Library west entry, created eight rectangular collision barriers before the navmesh bake, and made a winding route with false turns/dead ends. The route uses the existing doorway back to the school halls and onward toward the Lab; no new Library exit was added.
- On first entry while the Book is uncollected, the monster appears inside the doorway's left side and navigates after the player at 0.22 m/s. Library encounter handling keeps it out of SHORT_CHASE.
- Headless editor scan had no script parse errors; `git diff --check` passed. No runtime behavior verification was run.

## Library zigzag revision (2026-10-08)

- Moved the Book to the northeast corner and the monster's first-entry position to the northwest. Replaced the branching maze with four thicker collision rectangles forming a zigzag; the walls are in the navmesh bake, and the monster follows the player around them.
- Increased the provisional Library follow speed to 0.32 m/s while preserving the no-chase encounter behavior.
- No runtime gameplay verification was run.

## Library maze authored in Blender (2026-10-08)

- Added four editable `Library Maze Wall` objects under the `Library Maze Placeholders` collection in `assets.blend`, parented to Library Floor and tagged as bookshelf replacements. They are 0.35 m thick and form the zigzag to the northeast Book corner.
- Exported `assets/school_blockout.glb` and removed runtime duplicate maze generation. The preview retains the northwest monster entry, northeast Book placement, and 0.32 m/s path-follow behavior.
- Blender save/export and Godot headless asset reimport completed; `git diff --check` passed. Godot reported its Windows certificate store and user editor-settings write warnings. No gameplay runtime verification was run.

## User-updated Library rectangles synchronized (2026-10-08)

- Preserved the user's latest rectangle edits in `assets.blend`, re-exported `assets/school_blockout.glb`, and reimported the updated school model in Godot.
- Godot completed the asset import with no script parse/import errors; `git diff --check` passed. The editor reported its known Windows certificate-store and outside-workspace settings warnings. No gameplay runtime verification was run.

## Library maze follow speed adjustment (2026-10-08)

- Increased provisional Book encounter follow speed to 0.5 m/s; maze navigation and no-chase behavior are unchanged.
- No runtime verification was run.

## Book pickup sink and stalking resume (2026-10-08)

- Book pickup animates the monster sinking 3.2 m over 1.25 seconds with collision disabled, then hides it. The relocation timer resumes after the animation; a hidden source can relocate normally, while destinations still require off-camera/occlusion approval. Successful relocation makes the monster visible again. Bell or a new item encounter interrupts the sink safely.
- Godot headless editor parse scan and `git diff --check` passed. Existing Windows certificate-store/settings warnings remain. No runtime gameplay verification was run.

## Locker Room lockers and Weight response (2026-10-08)

- Located the two Locker Room door openings from `assets.blend`; created six open-front rectangular locker placeholders in the preview along both side walls and spaced them away from the openings. E hides the player in the closest locker and E exits into its clear approach area; the hidden player is invisible, stationary, collision-free, and not targetable even during Bell pursuit.
- Moved the Weight marker north. The room encounter now patrols north-to-south; any player or door noise triggers a fast approach and brief look before the monster resumes its patrol. The Weight encounter suppresses chase behavior.
- Changed `scenes/school_blockout_preview.gd`, `scenes/monster_placeholder.gd`, `After-School-AI-GDD/docs/PROGRESS.md`. No runtime verification was run.
- Follow-up: made E collect a nearby item before entering a locker; when already hidden, E continues to exit first. This resolves the overlapping Weight/locker interaction range. No gameplay run was performed for this input-priority change.
- Follow-up: after Weight pickup, the monster now pathfinds toward the Gym at 3.5 m/s, using the existing doorway navigation links and squeeze behavior. Automatic relocation remains paused until it arrives, then resumes. Headless scene load completed without script parse errors; door traversal was not interactively tested.
- Fixed the missing indentation under the preview-item `else` branch that caused Godot's parser error. A headless scene load completed without script parse errors. It still reports an existing missing `artroom floor` item warning and environment log/certificate-store warnings; no interactive gameplay verification was run.
- Fixed the reported missing-floor warning by aligning the Brush/Artroom lookup with `Cafeteria Floor` (the floor carrying the Artroom label) and the Snack/Cafeteria lookup with `Cafe Floor` (the floor carrying the Cafeteria label). Updated room registration, cafeteria window markers, and excluded-floor lists to follow those names. Headless scene load now reports no script parse or missing-floor warnings; environment log/certificate-store warnings persist.
- Consolidated final behavior/status: six open-front locker placeholders; E hides/exits safely; nearby item pickup takes priority on E; Weight is at the north; the Weight encounter patrols northâ€“south, investigates any noise and returns to patrol without chasing; Weight pickup sends the monster running to the Gym at 3.5 m/s, after which the regular relocation timer resumes. Brush/Artroom and Snack/Cafeteria room-floor mappings match the Blender model. Changed files are `scenes/school_blockout_preview.gd`, `scenes/monster_placeholder.gd`, and `After-School-AI-GDD/docs/PROGRESS.md`. Headless scene load had no script-parse or missing-floor warnings. Interactive route/door traversal remains unchecked; closed doors block the monster.

## Cafeteria Snack kitchen peek encounter (2026-10-08)

- Read the Snack interaction notes: use cafeteria tables/counters/serving area as line-of-sight cover and crouch while crossing. The user specified the Snack marker at the northwest and revised the behavior to have the monster peek from the kitchen on a timer, rushing exposed players.
- Moved the Snack pickup circle to the Cafeteria northwest. Opened the kitchen's south wall into a wide serving pass-through with a counter, and added three long collidable tables as cover. Geometry is generated in the Godot preview before the navmesh bake.
- The monster waits in the kitchen, approaches the serving opening after a random 3–5 second delay, and checks line of sight during a 1.5-second peek. If it sees the player, it rushes at 7 m/s; breaking line of sight lets it return to the kitchen. Crouching lowers the sight-ray target behind table cover. Sight distance/width, peek interval/duration, and rush speed are exported temporary settings.
- Changed scenes/school_blockout_preview.gd, scenes/monster_placeholder.gd, and After-School-AI-GDD/docs/PROGRESS.md. git diff --check passed. Gameplay verification was not run; the kitchen entrance, navigation route, and table sightlines remain to be checked in the running preview.

- Follow-up: Added two editable cafeteria tables and a west-side kitchen pass-through in assets.blend; aligned the Godot preview with Blender and removed the middle table.
- Follow-up: The monster now stays at one kitchen watch point, turns toward the south and west openings on timed intervals, and uses a 6 m spotlight half-width. When spotted, it pathfinds through an opening and compresses under the low header, then returns to its watch point after losing sight.
- No Godot runtime verification was run for these follow-ups.

## Ruler hallway locker encounter (2026-10-08)

- Changed the preview Ruler so its encounter begins on pickup rather than on entry to Classroom B. Pickup queues an off-camera spawn in the hall in front of Classroom A; the monster then follows the player through navigation at 0.55 m/s. If the player progresses around the hall toward Science, it queues an off-camera fallback spawn in front of the Science Classroom and follows from there.
- Added six open-front locker placeholders in a row beneath the east hallway's narrow high window. E hides the player in a hallway locker; during this encounter the Locker Room lockers do not count as hiding spots. While the player is concealed in one of the six hallway lockers, the monster ignores the hidden player and continues past the row to the far end. Reaching that end completes the encounter and resumes the normal relocation timer. Hiding in the existing Locker Room lockers remains available outside this encounter.
- Hallway lockers are created before navigation baking so the monster path can route around them. The monster still waits until both its current body and requested spawn are camera-occluded/out of view before teleporting. This remains preview-only and does not add capture behavior or production inventory/event wiring.
- Godot headless scene startup completed and printed the expected preview door/navigation/window setup with no GDScript parse errors. The environment continues to report existing log-folder/root-certificate warnings. Interactive encounter routing and visual locker alignment have not been play-checked.
- **Ruler encounter follow-up (2026-10-08):** Moved the fallback spawn onto the hallway side directly in front of the Science Classroom south door, using the modeled preview door node rather than an estimated room-floor offset. The encounter follow speed is now 1.1 m/s (double the previous 0.55 m/s) so the monster can block the route toward Science. No gameplay verification was run for this adjustment.
- **Ruler hallway return escalation (2026-10-08):** The encounter now tracks which end of the corridor the monster is at. When the player crosses back to the opposite hallway, the monster queues an off-camera relocation to that end; the first move from Classroom A toward Science is unboosted, then each subsequent hallway return triples the chase-walk speed again (3.3 m/s, 9.9 m/s, and so on from the 1.1 m/s base). This loop stops once the player hides in one of the six hallway lockers; the monster then passes the row and completes the event. No gameplay verification was run.
- **Ruler locker corner follow-up (2026-10-08):** While the player remains hidden in a hallway locker, the monster now first reaches the far end of the locker row, then follows a second navigation target around the hallway corner. The event completes only after it reaches that corner, at which point the regular off-camera teleport countdown resumes. Leaving the locker resets the corner-turn phase so the monster returns to following the player. No gameplay verification was run.
- **Ruler locker pass fix (2026-10-08):** The likely cause was that the navmesh treated the wide gaps between the locker placeholders as passable even though the monster capsule could not fit. Widened the six shells so the bake closes those gaps and routes the monster around the row ends; moved the pass/corner targets closer to the locker row so they remain in the hallway. No gameplay verification was run.
- **Ruler continuous movement adjustment (2026-10-08):** Removed player-distance stopping from the hallway sequence. The monster now walks between the north and south hallway waypoints continuously, turns at each end while the player remains visible, and reverses its route after each end turn. When the player hides in a hallway locker, it completes the current pass and corner turn, then resumes regular relocation. If navigation briefly reports an empty/finished path, the Ruler movement uses the active waypoint as a fallback so it does not idle.
- **Ruler final corner completion (2026-10-08):** When the monster reaches the corner while the player is hidden, it now ends the hallway event immediately instead of reversing for another pass. Completion clears the escalation multiplier/count and the regular relocation timer resumes from zero.
- **Ruler interaction timeout (2026-10-08):** Added a 20-second fallback. After it expires, the monster continues its hallway sequence until a regular spawn candidate is available with both its current body and destination outside camera view/occluded. It then performs one regular off-camera relocation, ends the Ruler interaction, resets the speed escalation, and resumes the standard 10-second relocation cycle. Failed visibility checks keep the fallback pending and retry every 0.25 seconds.
- **Ruler spotlight tracking (2026-10-08):** During the Ruler hallway encounter, the spotlight now turns independently to face the player continuously. When the player hides in a hallway locker, it holds its last direction and resumes tracking after the player exits. No gameplay verification was run.
- **Ruler spotlight chase (2026-10-08):** If the player is inside the tracked spotlight with clear line of sight, the monster now enters chase at 8.0 m/s. Hiding in a hallway locker prevents spotlight detection and exits chase so the scripted hallway pass can continue. No gameplay verification was run.

## Auditorium Microphone preview encounter (2026-10-08)

- Added the Microphone to the Auditorium preview item list at the north end of a straight center aisle. `assets.blend` now contains an editable raised stage, two centered steps, a microphone stand placeholder, and 30 separate chairs flanking the aisle. Re-exported `assets/school_blockout.glb` for Godot.
- The monster waits onstage facing away. Walking/running noise makes it slowly turn toward the player; a clear spotlight hit starts its navigation chase. Collecting the Microphone starts a persistent chase toward the auditorium exit. Once the player clears the south doorway, the double door slams shut and the monster returns to the regular off-camera relocation cycle.
- Chair backs and the stage/steps are collision-backed in the preview. The controller uses provisional 28-degree/second turning, 1.5-second noise attention, 0.8-second sight grace, and 6.5 m/s chase settings. The encounter remains preview-only; no authoritative inventory or objective integration was added.
- Blender background save and GLB export succeeded. Godot was not run for this change, so spotlight cover, stage-step navigation, door selection, and the exit sequence remain unchecked in gameplay.
- Changed `create_auditorium_microphone.py`, `assets.blend`, `assets/school_blockout.glb`, `scenes/auditorium_microphone_encounter.gd`, `scenes/school_blockout_preview.gd`, and `scenes/preview_school_door.gd`.

- Microphone encounter follow-up (2026-10-08): Extended the stage spotlight cone to cover the Auditorium's width and depth. After the Microphone is collected, the monster turns toward the player for 3 seconds, pauses for 3 seconds, then begins chasing. The Auditorium south door is locked until pickup, then opens manually with E when the player is beside it; it closes after the player exits. No runtime play-check was performed.

- Auditorium door interaction fix (2026-10-08): Increased the manual E interaction reach across the door plane to 2 meters because player collision prevents standing directly against the panel. No runtime play-check was performed.

- Auditorium door behavior clarification (2026-10-08): Removed E-key opening. The south door opens automatically as the player approaches after the Microphone pickup, then is locked and slammed shut at encounter end so it cannot reopen. No runtime play-check was performed.

- Auditorium auto-open reliability (2026-10-08): Expanded the south exit automatic approach trigger to 2 meters so the player capsule can activate it before door collision stops forward movement. It remains locked until Microphone pickup and locked again after the escape. No runtime play-check was performed.

- Auditorium door restored to standard behavior (2026-10-08): Removed its initial lock and special trigger distance; it now uses the default proximity opening shared by the other preview doors. The encounter locks and slams it shut at the end so it cannot reopen. No runtime play-check was performed.

- Microphone noise response turn (2026-10-08): Increased the monster's noise-response turning speed to 90 degrees per second; its normal turn speed remains unchanged. No runtime play-check was performed.

- Microphone pursuit spotlight aim (2026-10-08): During B-line/chase movement, the monster turns toward the player's current position so its searchlight tracks the player while navigation routes around obstacles. No runtime play-check was performed.

- Artroom Brush ceiling search preview (2026-10-08): After Brush pickup, the monster hangs upside down from the Artroom ceiling and sweeps a narrow opaque triangular light over the floor from the room center. The Cafeteria-labeled Artroom hallway door closes and becomes one-way from the hallway side; the player must exit via the Bathroom door and reach the circulation hallway. The controller then restores the monster's regular position, collision, and AI and restarts the normal relocation timer. No runtime or interactive route verification was performed.

- Artroom Brush spotlight chase (2026-10-08): The sweeping floor light now checks for player overlap with line of sight; when it catches the player, the light stops and the monster drops to floor height and B-lines toward them at its normal chase speed. Godot headless scene load completed without script errors.

- Artroom Brush chase visibility fix (2026-10-08): On spotlight detection the monster is made visible, restored upright, moved to player floor height, and its physics processing is re-enabled before the chase starts. Headless scene load has no script errors.

- Library maze restored to Godot export (2026-10-08): Re-exported the existing school contents plus all seven Library Maze Wall objects from assets.blend into assets/school_blockout.glb. Godot reimported the GLB, and the headless preview loads with doors/navigation initialized and no script errors.

- Final key Bell escape sequence (2026-10-09): Replaced the debug-toggle transition with a dedicated final-key handler. It spawns the monster at the farthest navigable corner of the Storage Closet from the player, then starts permanent Bell chase and directs the player to the entrance. Fixed the crash by passing a typed Array[StringName] when clearing safe rooms. A headless repro collected the key and confirmed BELL_CHASE, visible monster, and spawn inside the key room.

- Final Bell suspense chase (2026-10-09): Added a five-second configurable pause after final-key pickup. During the final Bell, the monster pathfinds to a point 3.5 m behind a moving player; when the player stops, it targets the player's position and closes in. Added provisional movement threshold and follow-distance exports. A headless scene repro verified the five-second delay and that a stationary player is pursued afterward.

- Final key entrance door sequence (2026-10-09): Final-key pickup finds the lobby door nearest the outside floor and starts opening it. Once the player crosses through and reaches the exterior side, that door locks and slams shut behind them. Headless repro confirmed the Lobby - 23 entrance opens, crossing triggers the slam, and the door stays locked/closed.
- Final-key exit door check (2026-10-09): Confirmed the Lobby - 23 entrance door swings open on final-key activation, remains open during the escape, and only slams and locks after the player reaches the exterior side. The door opens toward the Lobby so the leaf clears the exit.
- Final-key entrance target correction (2026-10-09): Corrected the final escape from the west Lobby-to-outside doorway (Lobby - 23) to the south/front entrance (Lobby - 22). The door remains open until the player crosses outward through that entrance, then slams and locks. A headless geometry check confirmed the selected door and crossing trigger.
- Bell hallway spawn and direct pursuit (2026-10-09): The regular Z-triggered Bell phase waits for an off-camera hallway spawn, pauses for three seconds, then directly pursues the player. Final-key pickup remains a separate interaction: it spawns the monster in the farthest navigable Storage Closet corner, keeps its five-second pause and trailing-distance chase, and does not relocate after chase starts. No Godot runtime test was run for this update.

- Regular Bell chase adjustment (2026-10-09): The Z-triggered Bell now spawns from an off-camera hallway location, waits three seconds, and pathfinds directly to the player. The final-key Storage Closet interaction retains its existing five-second delay and trailing-distance chase. Updated progress notes; no runtime test was run.
