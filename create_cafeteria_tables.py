import bpy
from mathutils import Vector


COLLECTION_NAME = "After School - School Blockout"
TABLE_PREFIX = "Cafeteria Table"
TABLE_LENGTH_FRACTION = 0.62
TABLE_WIDTH = 0.7
TABLETOP_HEIGHT = 0.92
TABLETOP_THICKNESS = 0.1
TABLE_LEG_WIDTH = 0.1
TABLE_WALL_OFFSETS = (0.85, 2.95)


def world_bounds(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return (
        min(point.x for point in points), max(point.x for point in points),
        min(point.y for point in points), max(point.y for point in points),
        min(point.z for point in points), max(point.z for point in points),
    )


def add_box(collection, name, dimensions, location, material):
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
    return obj


def main():
    collection = bpy.data.collections.get(COLLECTION_NAME)
    if collection is None:
        raise RuntimeError("School collection not found: " + COLLECTION_NAME)
    cafe_floor = bpy.data.objects.get("Cafe Floor") or bpy.data.objects.get("Cafe floor - muted tile")
    kitchen_south_wall = bpy.data.objects.get("Kitchen - South Wall")
    if kitchen_south_wall is None:
        kitchen_south_wall = bpy.data.objects.get("Kitchen inset partitions")
    if cafe_floor is None or kitchen_south_wall is None:
        raise RuntimeError("Cafe Floor or Kitchen - South Wall was not found")

    # Remove a previous generated set so this script can be safely rerun.
    for obj in list(collection.all_objects):
        if obj.name.startswith(TABLE_PREFIX):
            bpy.data.objects.remove(obj, do_unlink=True)

    floor_min_x, floor_max_x, floor_min_y, floor_max_y, floor_min_z, floor_max_z = world_bounds(cafe_floor)
    wall_min_x, wall_max_x, wall_min_y, wall_max_y, wall_min_z, wall_max_z = world_bounds(kitchen_south_wall)
    cafe_width = floor_max_x - floor_min_x
    x_center = (floor_min_x + floor_max_x) * 0.5
    floor_z = (floor_min_z + floor_max_z) * 0.5
    wall_y = (wall_min_y + wall_max_y) * 0.5

    # The Cafeteria floor overlaps the Kitchen footprint. Pick the side of
    # the south wall with more clear floor area and keep the tables in it.
    lower_space = wall_min_y - floor_min_y
    upper_space = floor_max_y - wall_max_y
    cafe_direction = -1.0 if lower_space >= upper_space else 1.0
    wall_edge = wall_min_y if cafe_direction < 0.0 else wall_max_y
    colors = bpy.data.materials.get("Preview Cafeteria Table")
    if colors is None:
        colors = bpy.data.materials.new("Preview Cafeteria Table")
        colors.diffuse_color = (0.43, 0.48, 0.49, 1.0)

    for index, distance_from_wall in enumerate(TABLE_WALL_OFFSETS):
        root = bpy.data.objects.new("%s %02d" % (TABLE_PREFIX, index + 1), None)
        root.empty_display_type = "CUBE"
        root.empty_display_size = 0.35
        collection.objects.link(root)
        # Keep both remaining tables clear of the kitchen wall and leave the
        # former middle row open for the user to arrange the room.
        table_y = wall_edge + cafe_direction * distance_from_wall
        root.location = (x_center, table_y, floor_z + TABLETOP_HEIGHT * 0.5)
        root["preview_prop"] = True
        root["room"] = "cafeteria"

        top = add_box(
            collection,
            "%s %02d Top" % (TABLE_PREFIX, index + 1),
            (cafe_width * TABLE_LENGTH_FRACTION, TABLE_WIDTH, TABLETOP_THICKNESS),
            (x_center, table_y, floor_z + TABLETOP_HEIGHT - TABLETOP_THICKNESS * 0.5),
            colors,
        )
        top.parent = root
        top.matrix_parent_inverse = root.matrix_world.inverted()

        leg_height = TABLETOP_HEIGHT - TABLETOP_THICKNESS
        leg_z = floor_z + leg_height * 0.5
        length = cafe_width * TABLE_LENGTH_FRACTION
        for end in (-1.0, 1.0):
            for side in (-1.0, 1.0):
                leg = add_box(
                    collection,
                    "%s %02d Leg %s %s" % (TABLE_PREFIX, index + 1, "L" if end < 0 else "R", "F" if side < 0 else "B"),
                    (TABLE_LEG_WIDTH, TABLE_LEG_WIDTH, leg_height),
                    (x_center + end * (length * 0.5 - TABLE_LEG_WIDTH), table_y + side * (TABLE_WIDTH * 0.5 - TABLE_LEG_WIDTH), leg_z),
                    colors,
                )
                leg.parent = root
                leg.matrix_parent_inverse = root.matrix_world.inverted()

        root.parent = cafe_floor
        root.matrix_parent_inverse = cafe_floor.matrix_world.inverted()

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("Added %d editable cafeteria table placeholders to" % len(TABLE_WALL_OFFSETS), bpy.data.filepath)


main()
