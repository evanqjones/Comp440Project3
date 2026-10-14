"""Export the reusable Blender locker prototypes to assets/lockers.glb."""
from pathlib import Path
import bpy

collection = bpy.data.collections.get("School - Locker Asset Prototypes")
if collection is None:
    raise RuntimeError("Run create_school_lockers.py before exporting locker assets")

roots = [
    bpy.data.objects[name]
    for name in ("School Locker Single", "School Locker Hall Bank")
    if name in bpy.data.objects
]
if len(roots) != 2:
    raise RuntimeError("Expected both locker prototype roots")

old_locations = {obj: obj.location.copy() for obj in roots}
try:
    for obj in roots:
        obj.location.y = 0.0
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = roots[0]
    output = Path(bpy.data.filepath).parent / "assets" / "lockers.glb"
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_extras=True,
    )
    print("Locker variants exported to", output)
finally:
    for obj, location in old_locations.items():
        obj.location = location
