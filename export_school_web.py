"""Run with Blender: blender --background assets.blend --python export_school_web.py.

Refresh the portable school model used by Web builds without saving or changing
the Blender source. Export every scene object, matching Godot's .blend import.
"""
from pathlib import Path
import bpy

output = Path(bpy.data.filepath).parent / "assets" / "school_web.glb"
bpy.ops.export_scene.gltf(
    filepath=str(output),
    export_format="GLB",
    use_selection=False,
    use_visible=False,
    export_apply=True,
    export_yup=True,
    export_extras=True,
    export_cameras=True,
    export_lights=True,
)
print("Web school exported to", output)
