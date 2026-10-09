# Godot School Blockout Preview

The current Blender school layout is exported to `assets/school_blockout.glb`.

The configured project main scene is `scenes/demo_scene.tscn`. Press **F5** to run the integrated Demo Scene. `scenes/school_blockout_preview.tscn` remains the separate Mechanics preview. Both load the current Blender export from `assets.blend` through Godot's imported asset pipeline.

The Mechanics preview retains its `Z` debug Bell toggle and prototype behavior. The Demo Scene integrates progression, doors, objectives, timed Bell phases, item encounters, and capture resets. Its monster search cone is hidden while detection remains active. Regular Bell phases activate five safe rooms; final escape has no safe rooms. Bell lighting turns off overhead fixtures while safe-room fixtures stay on, and non-safe fluorescent fixtures flicker during ordinary play. Touching the monster returns the player to the latest collected-item checkpoint and ends an active regular Bell; during the final chase, player and monster return to their saved chase-start positions and the chase delay restarts. These Demo values are integration behavior, distinct from the Mechanics preview's debug toggle.

`scenes/player_placeholder.tscn` is the reusable third-person player capsule. Use **WASD** to move, **Shift** to sprint, and **Space** to sneak; use the mouse to orbit. Press **Escape** to release the mouse and click the game window to capture it again. The Demo HUD shows the sneak/sprint hints and reminds players to avoid the monster's eyes.

## Preview doors and door noise

The preview now creates collision-backed single and double doors from the modeled doorway headers. Doors start opening when the player is within 0.5 m of the doorway, swinging away from the side that pushed them; their leaves take 1.8 seconds to move and release collision when fully open so the player can cross. They stay open afterward, except the one-way Locker Room hallway door: it opens from the Locker Room side and swings shut after the player clears the doorway. Opening a door emits a preview noise event at 70% strength. If the monster is within 10 m, it turns and walks to investigate. If farther away, it tries spawn points closest to the doorway while off camera, then enters INVESTIGATE and slowly approaches the sound at a provisional 0.5 m/s. The monster resumes hallway pacing after its investigation timer completes. Door opening time, approach distance, one-way hold time, investigation speed/radius/duration, and door response chance are provisional preview settings.

Monster doorway squeeze currently reduces its capsule to a provisional 15% width and 1.2 m height. A headless traversal check confirmed it crosses an open Auditorium doorway and returns to its 3 m standing height.

## Crouch and movement noise

Hold **Space** to crouch at a provisional 2.0 m/s. The player capsule and camera lower while crouched; sprint is suppressed. Crouching emits no movement noise. Walking emits a quiet `NoiseEvent` every 0.8 seconds while moving, and sprinting emits a loud event at the same interval. In this preview, a nearby quiet event has a 30% chance to make the monster turn toward the player without moving; a loud event uses the existing 70% door-noise response chance and investigation/relocation behavior. The event interval and response distances are provisional. This is gameplay noise signaling; no footstep audio clips are included yet.

If the monster makes no meaningful progress toward an investigation sound for 15 seconds, it retries relocation every second until it finds a valid marker. It checks both its current body and the destination against the player camera before moving; it stays put when every candidate is visible. This fallback is disabled during Bell.

While investigating, the monster keeps checking its search cone and enters SHORT_CHASE if it sees the player. Nearby walking or running noise makes it turn toward the player while it continues investigating. The normal patrol noise-response chances are unchanged.
