"""Export only the lobby and hallway prop prototypes for Godot."""
from pathlib import Path
import bpy


collection = bpy.data.collections.get("School - Lobby Hallway Prop Prototypes")
if collection is None:
    raise RuntimeError("Run create_school_dressing_assets.py first")

bpy.ops.object.select_all(action="DESELECT")
for obj in collection.all_objects:
    obj.select_set(True)
if not collection.all_objects:
    raise RuntimeError("No school dressing prototypes were created")
bpy.context.view_layer.objects.active = next(
    obj for obj in collection.all_objects if obj.parent is None
)

output = Path(bpy.data.filepath).parent / "assets" / "school_dressing.glb"
bpy.ops.export_scene.gltf(
    filepath=str(output),
    export_format="GLB",
    use_selection=True,
    use_visible=False,
    export_apply=True,
    export_yup=True,
    export_extras=True,
    export_cameras=False,
    export_lights=False,
)
print("School lobby and hallway prop prototypes exported to", output)
