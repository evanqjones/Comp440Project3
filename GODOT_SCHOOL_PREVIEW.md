# Godot School Blockout Preview

The current Blender school layout is exported to `assets/school_blockout.glb`.

Open `scenes/school_blockout_preview.tscn` and run that scene with **F6** to view the school blockout. It loads the GLB at runtime, generates static collision shapes from floor and wall meshes, and places the cyan capsule at the Nurse Office floor.

`scenes/player_placeholder.tscn` is a reusable `CharacterBody3D` capsule with matching collision and a third-person camera. Use **WASD** to move relative to the camera and the **mouse** to orbit the camera. Press **Escape** to release/capture the mouse; click the game window to capture it again. The movement and camera values are provisional exports in `player_placeholder.gd`. The Godot project main scene remains unassigned.
