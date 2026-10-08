import bpy
from mathutils import Vector


COLLECTION_NAME = "After School - School Blockout"
WALL_NAME = "Kitchen - West Wall"
PART_PREFIX = "Kitchen - West Opening"
OPENING_WIDTH = 2.4
OPENING_HEIGHT = 2.4


def world_bounds(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return (
        min(point.x for point in points), max(point.x for point in points),
        min(point.y for point in points), max(point.y for point in points),
        min(point.z for point in points), max(point.z for point in points),
    )


def add_wall_piece(collection, floor, name, dimensions, location, material):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material is not None:
        obj.data.materials.append(material)
    for existing_collection in list(obj.users_collection):
        existing_collection.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = floor
    obj.matrix_parent_inverse = floor.matrix_world.inverted()
    obj["preview_opening_frame"] = True
    return obj


def main():
    collection = bpy.data.collections.get(COLLECTION_NAME)
    if collection is None:
        raise RuntimeError("School collection not found: " + COLLECTION_NAME)
    floor = bpy.data.objects.get("Kitchen Floor")
    wall = bpy.data.objects.get(WALL_NAME)
    if floor is None:
        raise RuntimeError("Kitchen Floor was not found")

    # The original wall is replaced with three individually editable pieces.
    existing_parts = [obj for obj in collection.all_objects if obj.name.startswith(PART_PREFIX)]
    for obj in existing_parts:
        bpy.data.objects.remove(obj, do_unlink=True)
    if wall is None:
        raise RuntimeError("Kitchen west wall was not found; cannot rebuild its opening")

    bounds = world_bounds(wall)
    material = wall.data.materials[0] if wall.data.materials else None
    x_min, x_max, y_min, y_max, z_min, z_max = bounds
    span_y = y_max - y_min
    opening_width = min(OPENING_WIDTH, span_y * 0.75)
    opening_height = min(OPENING_HEIGHT, (z_max - z_min) * 0.55)
    panel_width = (span_y - opening_width) * 0.5
    center_x = (x_min + x_max) * 0.5
    center_y = (y_min + y_max) * 0.5
    center_z = (z_min + z_max) * 0.5

    add_wall_piece(
        collection, floor, PART_PREFIX + " South Panel",
        (x_max - x_min, panel_width, z_max - z_min),
        (center_x, y_min + panel_width * 0.5, center_z), material,
    )
    add_wall_piece(
        collection, floor, PART_PREFIX + " North Panel",
        (x_max - x_min, panel_width, z_max - z_min),
        (center_x, y_max - panel_width * 0.5, center_z), material,
    )
    add_wall_piece(
        collection, floor, PART_PREFIX + " Header",
        (x_max - x_min, opening_width, z_max - z_min - opening_height),
        (center_x, center_y, z_min + (z_max - z_min + opening_height) * 0.5), material,
    )
    bpy.data.objects.remove(wall, do_unlink=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("Opened the Kitchen west wall toward the Cafeteria in", bpy.data.filepath)


main()
