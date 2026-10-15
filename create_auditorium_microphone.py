import bpy
from mathutils import Vector


COLLECTION_NAME = "After School - School Blockout"
PREFIX = "Auditorium Encounter"


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


def add_cylinder(collection, name, radius, depth, location, material, vertices=16, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location,
        rotation=rotation or (0.0, 0.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    if material is not None:
        obj.data.materials.append(material)
    for existing_collection in list(obj.users_collection):
        existing_collection.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def make_material(name, color, roughness=0.78):
    material = bpy.data.materials.get(name)
    if material is None:
        material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.roughness = roughness
    return material


def parent_preserve_world(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def main():
    school_collection = bpy.data.collections.get(COLLECTION_NAME)
    assembly_collection = bpy.data.collections.get("02 - Room Assemblies (floor parents)")
    floor = bpy.data.objects.get("Auditorium Floor")
    if school_collection is None or assembly_collection is None or floor is None:
        raise RuntimeError("The auditorium school collection/floor was not found")

    for obj in list(school_collection.all_objects):
        if obj.name.startswith(PREFIX):
            bpy.data.objects.remove(obj, do_unlink=True)

    min_x, max_x, min_y, max_y, min_z, max_z = world_bounds(floor)
    center_x = (min_x + max_x) * 0.5
    floor_z = max_z
    room_depth = max_y - min_y
    north_edge = max_y

    stage_material = make_material("Preview Auditorium Stage", (0.22, 0.16, 0.12))
    stage_trim = make_material("Preview Auditorium Stage Trim", (0.38, 0.27, 0.18))
    chair_material = make_material("Preview Auditorium Chair", (0.13, 0.20, 0.27))
    chair_frame = make_material("Preview Auditorium Chair Frame", (0.11, 0.12, 0.13))
    mic_material = make_material("Preview Auditorium Microphone", (0.46, 0.49, 0.52), 0.42)

    # The auditorium's south entrance is at the lower-Y end. Keep a full-width
    # center aisle open from that door to the microphone just in front of stage.
    stage_width = min(7.8, max_x - min_x - 1.2)
    stage_depth = min(1.85, room_depth * 0.17)
    stage_front_y = north_edge - stage_depth - 0.12
    stage_center_y = stage_front_y + stage_depth * 0.5
    stage_height = 0.48
    stage_root = bpy.data.objects.new(PREFIX + " - Stage", None)
    stage_root.empty_display_type = "CUBE"
    stage_root.empty_display_size = 0.35
    school_collection.objects.link(stage_root)
    stage_root.location = (center_x, stage_center_y, floor_z)
    stage_root["room"] = "Auditorium"
    stage_root["preview_prop"] = True
    stage_top = add_box(
        school_collection, PREFIX + " Stage Platform",
        (stage_width, stage_depth, stage_height),
        (center_x, stage_center_y, floor_z + stage_height * 0.5), stage_material,
    )
    parent_preserve_world(stage_top, stage_root)
    stage_front = add_box(
        school_collection, PREFIX + " Stage Front Trim",
        (stage_width, 0.10, 0.12),
        (center_x, stage_front_y + 0.035, floor_z + stage_height - 0.06), stage_trim,
    )
    parent_preserve_world(stage_front, stage_root)

    # Two low, broad steps connect the aisle to the raised platform.
    step_footprint = 0.62
    for index, step_height in enumerate((0.32, 0.16)):
        step_depth = step_footprint
        step_back_y = stage_front_y - step_footprint * index
        step_front_y = step_back_y - step_depth
        step_center_y = (step_front_y + step_back_y) * 0.5
        step = add_box(
            school_collection, "%s Stage Step %02d" % (PREFIX, index + 1),
            (2.25, step_depth, step_height),
            (center_x, step_center_y, floor_z + step_height * 0.5), stage_trim,
        )
        parent_preserve_world(step, stage_root)

    mic_y = stage_front_y - 1.75
    mic_root = bpy.data.objects.new(PREFIX + " - Microphone Stand", None)
    mic_root.empty_display_type = "CIRCLE"
    mic_root.empty_display_size = 0.24
    school_collection.objects.link(mic_root)
    mic_root.location = (center_x, mic_y, floor_z)
    mic_root["item_id"] = "microphone"
    mic_root["room"] = "Auditorium"
    for name, radius, depth, z, rotation in (
        ("Base", 0.17, 0.06, 0.04, None),
        ("Stem", 0.035, 1.24, 0.66, None),
        ("Head", 0.075, 0.24, 1.31, (1.5708, 0.0, 0.0)),
    ):
        part = add_cylinder(
            school_collection, "%s Microphone %s" % (PREFIX, name),
            radius, depth, (center_x, mic_y, floor_z + z), mic_material,
            vertices=12, rotation=rotation,
        )
        parent_preserve_world(part, mic_root)

    # Five rows of individual low-poly chairs flank the central approach.
    # Their backs face the stage so a crouched player can break the spotlight.
    chair_width = 0.62
    chair_depth = 0.62
    seat_height = 0.48
    seat_thickness = 0.10
    back_height = 0.58
    back_thickness = 0.08
    row_fractions = (0.78, 0.67, 0.56, 0.45, 0.34)
    side_offsets = (1.48, 2.28, 3.08)
    chair_index = 0
    for row_index, fraction in enumerate(row_fractions, start=1):
        row_y = min_y + room_depth * fraction
        for side in (-1.0, 1.0):
            for seat_index, offset in enumerate(side_offsets, start=1):
                chair_index += 1
                chair_x = center_x + side * offset
                root = bpy.data.objects.new(
                    "%s Chair %02d" % (PREFIX, chair_index), None
                )
                root.empty_display_type = "CUBE"
                root.empty_display_size = 0.22
                school_collection.objects.link(root)
                root.location = (chair_x, row_y, floor_z)
                root["row"] = row_index
                root["seat"] = seat_index
                root["room"] = "Auditorium"
                root["preview_prop"] = True

                parts = (
                    ("Seat", (chair_width, chair_depth, seat_thickness),
                     (chair_x, row_y, floor_z + seat_height - seat_thickness * 0.5), chair_material),
                    ("Back", (chair_width, back_thickness, back_height),
                     (chair_x, row_y - chair_depth * 0.5 + back_thickness * 0.5,
                      floor_z + seat_height + back_height * 0.5 - 0.03), chair_material),
                )
                for suffix, dimensions, location, material in parts:
                    part = add_box(
                        school_collection,
                        "%s Chair %02d %s" % (PREFIX, chair_index, suffix),
                        dimensions, location, material,
                    )
                    parent_preserve_world(part, root)
                leg_height = seat_height - seat_thickness
                for leg_x in (-1.0, 1.0):
                    for leg_y in (-1.0, 1.0):
                        leg = add_box(
                            school_collection,
                            "%s Chair %02d Leg" % (PREFIX, chair_index),
                            (0.055, 0.055, leg_height),
                            (chair_x + leg_x * (chair_width * 0.5 - 0.06),
                             row_y + leg_y * (chair_depth * 0.5 - 0.06),
                             floor_z + leg_height * 0.5), chair_frame,
                        )
                        parent_preserve_world(leg, root)
                parent_preserve_world(root, floor)

    parent_preserve_world(stage_root, floor)
    parent_preserve_world(mic_root, floor)

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in school_collection.all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = floor
    glb_path = bpy.path.abspath("//assets/school_blockout.glb")
    bpy.ops.export_scene.gltf(
        filepath=glb_path, export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True, export_extras=True,
    )
    print("Auditorium encounter created: stage, 2 steps, %d chairs, and microphone placeholder" % chair_index)
    print("Stage front Y: %.3f; microphone Y: %.3f; exported: %s" % (stage_front_y, mic_y, glb_path))


# The default operation now polishes the existing authored layout. The original
# blockout rebuild is retained only as an explicit authoring operation.
POLISH_TAG = "auditorium_polish_generator"


def polish_current_auditorium():
    import json
    import math
    import os
    import runpy
    from pathlib import Path
    from mathutils import Matrix

    root = Path(bpy.data.filepath).parent
    Builder = runpy.run_path(str(root / "create_cafeteria_library_props.py"))["Builder"]
    group_name = "School Props - Auditorium"
    old = bpy.data.collections.get(group_name)
    if old and (not old.get(POLISH_TAG) or old.children or any(not o.get(POLISH_TAG) for o in old.objects)):
        raise RuntimeError("Unowned auditorium collection")
    floor = bpy.data.objects["Auditorium Floor"]
    chairs = [bpy.data.objects.get(f"Auditorium Encounter Chair {i:02d}") for i in range(1,31)]
    if any(o is None for o in chairs):
        raise RuntimeError("Inspect current chair layout before polishing")
    # These collision meshes must remain byte-for-byte equivalent geometrically.
    collision = {o.name: [tuple(v.co) for v in o.data.vertices] for o in bpy.data.objects
                 if o.type == "MESH" and (o.name.startswith("Auditorium Encounter Stage") or
                 o.name.startswith("Auditorium Encounter Chair") and o.name.endswith(" Back"))}
    if old:
        for o in list(old.objects): bpy.data.objects.remove(o,do_unlink=True)
        bpy.data.collections.remove(old)
    for m in list(bpy.data.meshes):
        if m.get(POLISH_TAG) and m.users == 0: bpy.data.meshes.remove(m)
    group = bpy.data.collections.new(group_name)
    group[POLISH_TAG] = True
    bpy.data.collections[COLLECTION_NAME].children.link(group)
    materials = {k: bpy.data.materials["School Props - "+k] for k in
                 ("Chair","Metal","Laminate","Cabinet","Art","Canvas")}
    designs = {}
    objects = []

    def mesh(name,k):
        m = k.mesh(name,materials)
        # Builder is reused for beveling, but ownership belongs to this generator.
        if "cafeteria_library_generator" in m: del m["cafeteria_library_generator"]
        m[POLISH_TAG] = True
        designs[name] = m
        return m

    def place(name,m,parent,location=(0,0,0)):
        o = bpy.data.objects.new("Auditorium Finish - "+name,m)
        group.objects.link(o)
        o[POLISH_TAG] = True
        o["preview_collision_disabled"] = True
        o["collision_policy"] = "visual-only; original stage and cover retained"
        o.parent = parent
        o.matrix_parent_inverse = Matrix.Identity(4)
        o.location = location
        objects.append(o)
        return o

    # Reuse one mesh per seat and leg; fit inside the original exact footprint.
    k = Builder()
    k.box((.62,.60,.025),(0,0,-.0375),"Metal",.008)
    k.box((.60,.60,.075),(0,0,.0125),"Chair",.024)
    seat = mesh("Upholstered Seat",k)
    k = Builder();k.box((.055,.055,.38),(0,0,0),"Metal",.007)
    leg = mesh("Formed Chair Leg",k)
    k = Builder()
    k.box((.54,.026,.47),(0,-.216,.735),"Chair",.024)
    for x in (-.25,.25):
        k.box((.045,.045,.50),(x,-.27,.70),"Metal",.006)
        k.box((.045,.50,.035),(x,0,.25),"Metal",.005)
    detail = mesh("Chair Upholstery and Braces",k)
    for i,chair in enumerate(chairs,1):
        for part in chair.children:
            if part.type != "MESH": continue
            if " Seat" in part.name: part.data = seat
            elif " Leg" in part.name: part.data = leg
        place(f"Chair Detail {i:02d}",detail,chair)

    x0,x1,y0,y1,z0,z1 = world_bounds(floor)
    cx = (x0+x1)/2
    stage = bpy.data.objects["Auditorium Encounter Stage Platform"]
    sx0,sx1,sy0,sy1,sz0,sz1 = world_bounds(stage)
    # Panelled fascia occupies the old platform face, beside the unchanged steps.
    k = Builder()
    k.box((2.55,.045,.30),(0,0,.24),"Laminate",.012)
    for x in (-.84,0,.84):
        k.box((.77,.018,.20),(x,-.03,.24),"Cabinet",.008)
    fascia = mesh("Panelled Fascia",k)
    for i,side in enumerate((-1,1),1):
        o=place(f"Fascia {i}",fascia,floor)
        o.matrix_world = Matrix.Translation((cx+side*2.52,sy0-.025,z1))
    k = Builder()
    k.box((2.20,.075,.008),(0,0,0),"Metal",.003)
    nosing = mesh("Step Nosing",k)
    for i in (1,2):
        step=bpy.data.objects[f"Auditorium Encounter Stage Step {i:02d}"]
        bx0,bx1,by0,by1,bz0,bz1=world_bounds(step)
        o=place(f"Step Nosing {i}",nosing,floor)
        o.matrix_world=Matrix.Translation((cx,by0+.05,bz1+.004))
    # Pleated side drapes and a high valance frame the stage, clear of its center.
    k = Builder()
    for i in range(5):
        k.box((.105,.12 if i%2 else .18,2.45),(-.22+i*.11,0,1.225),"Art",.014)
    curtain=mesh("Pleated Side Drape",k)
    for i,side in enumerate((-1,1),1):
        o=place(f"Side Drape {i}",curtain,floor)
        o.matrix_world=Matrix.Translation((cx+side*3.55,y1-.28,z1+.58))
    k=Builder()
    k.box((7.75,.22,.32),(0,0,0),"Art",.018)
    k.box((7.78,.26,.055),(0,0,.17),"Laminate",.010)
    valance=mesh("Curtain Valance",k)
    o=place("Valance",valance,floor)
    o.matrix_world=Matrix.Translation((cx,y1-.27,z1+3.20))
    k=Builder()
    k.box((.11,1.10,1.25),(0,0,0),"Metal",.015)
    k.box((.025,.99,1.13),(.068,0,0),"Cabinet",.016)
    for z in (-.34,0,.34):
        k.box((.026,.96,.018),(.084,0,z),"Chair",0)
    panel=mesh("Acoustic Panel",k)
    for side in (-1,1):
        for i,fraction in enumerate((.28,.49,.69),1):
            o=place(f"Acoustic Panel {side} {i}",panel,floor)
            o.matrix_world=Matrix.Translation((x0+.19 if side<0 else x1-.19,y0+(y1-y0)*fraction,z1+2.20)) @ Matrix.Rotation(0 if side<0 else math.pi,4,"Z")
    k=Builder()
    for z in (.77,.86): k.cylinder(.048,.045,(0,0,z),"Metal",12)
    k.box((.08,.055,.045),(.045,0,.82),"Metal",.008)
    k.box((.12,.18,.012),(0,0,1.386),"Metal",.003)
    mic=mesh("Microphone Hardware",k)
    place("Microphone Hardware",mic,bpy.data.objects["Auditorium Encounter - Microphone Stand"])
    bpy.context.view_layer.update()
    for name,vertices in collision.items():
        assert [tuple(v.co) for v in bpy.data.objects[name].data.vertices] == vertices, name
    # A full 2.25 m center aisle is untouched; wall panels and stage drapes
    # remain well outside the Monster's central stage spawn/spotlight line.
    for o in objects:
        if "Chair Detail" in o.name or "Acoustic" in o.name or "Side Drape" in o.name:
            a,b,c,d,e,f=world_bounds(o)
            assert b < cx-1.125 or a > cx+1.125, "Center aisle intrusion: "+o.name
    # Replace orphaned previous generated meshes after reassigning seats/legs.
    for m in list(bpy.data.meshes):
        if m.get(POLISH_TAG) and m.users == 0: bpy.data.meshes.remove(m)
    for name,m in designs.items(): m.name = "School Auditorium Kit - "+name
    stats={"new_instances":len(objects),"chairs_refinished":30,"seat_leg_replacements":150,
           "designs":len(designs),"triangles_per_design":{n:len(m.loop_triangles) for n,m in designs.items()},
           "new_detail_triangles":sum(len(o.data.loop_triangles) for o in objects),
           "chair_triangles":len(seat.loop_triangles)+4*len(leg.loop_triangles)+len(detail.loop_triangles)+12,
           "collision_meshes_preserved":len(collision)}
    folder=Path(os.environ.get("TEMP","/tmp"))/"final-school-polish-review"
    folder.mkdir(exist_ok=True)
    (folder/"auditorium_report.json").write_text(json.dumps(stats,indent=2))
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print("AUDITORIUM_POLISH",json.dumps(stats,sort_keys=True))


if __name__ == "__main__":
    import sys
    if "--rebuild-blockout" in sys.argv:
        main()
    else:
        polish_current_auditorium()
