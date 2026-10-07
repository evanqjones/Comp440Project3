# Godot School Blockout Preview

The current Blender school layout is exported to `assets/school_blockout.glb`.

The project main scene is `scenes/school_blockout_preview.tscn`. Press **F5** to run the school blockout. It loads the GLB at runtime, generates static collision shapes from floor and wall meshes, and places the cyan capsule at the Nurse Office floor.

The preview includes a stationary monster placeholder near the Lobby: a 3 m dark capsule and an opaque yellow triangular search cone with a 6 m forward reach. Press **Z** to toggle the preview's red Bell lighting and status label. This is a visual debug toggle; it does not start a Bell timer, select safe rooms, or call School state. The monster has no movement, collision, capture, or player-reset behavior yet.

`scenes/player_placeholder.tscn` is the reusable `CharacterBody3D` capsule (0.6 m diameter and 1.65 m tall) with matching collision and a third-person camera. The reusable camera uses a 4.3 m spring arm. In the school preview only, the player instance is scaled to 0.8, making the capsule about 0.48 m wide and 1.32 m tall, and its camera distance is set to 3.5 m (2.8 m at preview scale); the reusable player scene remains unchanged. Use **WASD** to move relative to the camera and the **mouse** to orbit it. Press **Escape** to release/capture the mouse; click the game window to capture it again. Movement and camera values are provisional exports in `player_placeholder.gd`.
