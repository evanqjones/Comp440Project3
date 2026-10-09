import bpy
import math
from mathutils import Vector


COLLECTION_NAME = "School - Fluorescent Fixtures"
CEILING_Z = 5.5


def make_material(name, color, emission_strength=0.0, metallic=0.0, roughness=0.45):
	material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
	material.diffuse_color = (*color, 1.0)
	material.use_nodes = True
	principled = material.node_tree.nodes.get("Principled BSDF")
	if principled:
		principled.inputs["Base Color"].default_value = (*color, 1.0)
		principled.inputs["Metallic"].default_value = metallic
		principled.inputs["Roughness"].default_value = roughness
		emission_color = principled.inputs.get("Emission Color") or principled.inputs.get("Emission")
		if emission_color:
			emission_color.default_value = (*color, 1.0)
		emission = principled.inputs.get("Emission Strength")
		if emission:
			emission.default_value = emission_strength
	return material


def room_bounds(obj):
	points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
	return (
		min(point.x for point in points), max(point.x for point in points),
		min(point.y for point in points), max(point.y for point in points),
	)


def add_box_geometry(vertices, faces, material_indices, center, size, material_index):
	cx, cy, cz = center
	sx, sy, sz = size
	start = len(vertices)
	vertices.extend([
		(cx - sx / 2, cy - sy / 2, cz - sz / 2),
		(cx + sx / 2, cy - sy / 2, cz - sz / 2),
		(cx + sx / 2, cy + sy / 2, cz - sz / 2),
		(cx - sx / 2, cy + sy / 2, cz - sz / 2),
		(cx - sx / 2, cy - sy / 2, cz + sz / 2),
		(cx + sx / 2, cy - sy / 2, cz + sz / 2),
		(cx + sx / 2, cy + sy / 2, cz + sz / 2),
		(cx - sx / 2, cy + sy / 2, cz + sz / 2),
	])
	faces.extend([
		(start + 0, start + 3, start + 2, start + 1),
		(start + 4, start + 5, start + 6, start + 7),
		(start + 0, start + 1, start + 5, start + 4),
		(start + 1, start + 2, start + 6, start + 5),
		(start + 2, start + 3, start + 7, start + 6),
		(start + 3, start + 0, start + 4, start + 7),
	])
	material_indices.extend([material_index] * 6)


def add_fixture(collection, name, x, y, along_y=False, length=1.35):
	vertices, faces, material_indices = [], [], []
	if along_y:
		footprint = lambda a, b: (x + b, y + a)
	else:
		footprint = lambda a, b: (x + a, y + b)
	# Two suspension stems sit between the ceiling and shallow metal housing.
	for offset in (-length * 0.32, length * 0.32):
		rx, ry = footprint(offset, 0.0)
		add_box_geometry(vertices, faces, material_indices, (rx, ry, CEILING_Z - 0.145), (0.035, 0.035, 0.29), 0)
	add_box_geometry(vertices, faces, material_indices, (x, y, CEILING_Z - 0.34), (0.30, length, 0.10) if along_y else (length, 0.30, 0.10), 0)
	add_box_geometry(vertices, faces, material_indices, (x, y, CEILING_Z - 0.397), (0.255, length - 0.10, 0.018) if along_y else (length - 0.10, 0.255, 0.018), 1)
	mesh = bpy.data.meshes.new(name + " Mesh")
	mesh.from_pydata(vertices, [], faces)
	mesh.materials.append(HOUSING)
	mesh.materials.append(DIFFUSER)
	for polygon, material_index in zip(mesh.polygons, material_indices):
		polygon.material_index = material_index
	obj = bpy.data.objects.new(name, mesh)
	collection.objects.link(obj)
	obj["fixture_type"] = "Suspended fluorescent strip"
	obj["ceiling_z"] = CEILING_Z
	bevel = obj.modifiers.new("Soft molded edges", "BEVEL")
	bevel.width = 0.012
	bevel.segments = 2
	return obj


HOUSING = make_material("Fluorescent Fixture - Warm White Housing", (0.76, 0.79, 0.81), metallic=0.12, roughness=0.38)
DIFFUSER = make_material("Fluorescent Fixture - Warm White Diffuser", (1.0, 0.88, 0.68), emission_strength=1.35, roughness=0.24)

old_collection = bpy.data.collections.get(COLLECTION_NAME)
if old_collection:
	for obj in list(old_collection.objects):
		bpy.data.objects.remove(obj, do_unlink=True)
	bpy.data.collections.remove(old_collection)

school = bpy.data.collections.get("After School - School Blockout")
if school is None:
	raise RuntimeError("Could not find the school blockout collection")
fixtures = bpy.data.collections.new(COLLECTION_NAME)
school.children.link(fixtures)

room_floors = [
	obj for obj in school.all_objects
	if obj.type == "MESH" and obj.name.endswith(" Floor") and obj.name != "Outside Floor"
]
for floor in room_floors:
	min_x, max_x, min_y, max_y = room_bounds(floor)
	width, depth = max_x - min_x, max_y - min_y
	area = width * depth
	count = max(1, min(4, math.ceil(area / 65.0)))
	along_y = depth > width
	long_axis = depth if along_y else width
	length = min(1.55, max(0.90, long_axis * 0.24))
	for index in range(count):
		fraction = (index + 0.5) / count
		if along_y:
			x = (min_x + max_x) * 0.5
			y = min_y + depth * fraction
		else:
			x = min_x + width * fraction
			y = (min_y + max_y) * 0.5
		add_fixture(fixtures, "Fluorescent - %s - %02d" % (floor.name.removesuffix(" Floor"), index + 1), x, y, along_y, length)

# A continuous series across the open circulation areas between room blocks.
hallway_positions = [
	(20.0, 11.0, False), (23.5, 8.0, True), (23.5, 2.0, True),
	(23.0, -3.0, False), (22.5, -7.4, True), (22.3, -12.2, True),
	(22.2, -17.4, False), (24.5, -21.8, False), (5.0, 6.0, True),
	(7.5, 0.0, True), (7.5, -5.0, True), (12.8, -15.0, False),
	(22.5, -1.0, False), (26.0, -16.8, True),
]
for index, (x, y, along_y) in enumerate(hallway_positions, 1):
	add_fixture(fixtures, "Fluorescent - Hallway - %02d" % index, x, y, along_y, 1.55)

# The Demo Scene's locker hallway runs beside the east exterior wall at Godot
# X=40, Z=3.8..15.0. Blender's imported Y axis maps to negative Godot Z.
east_locker_hall_positions = [-5.2, -8.2, -11.2, -14.0]
for index, y in enumerate(east_locker_hall_positions, 1):
	add_fixture(fixtures, "Fluorescent - East Locker Hallway - %02d" % index, 38.45, y, True, 1.55)

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Created %d fixtures across %d rooms, %d general hallway positions, and %d east locker hallway positions" % (len(fixtures.objects), len(room_floors), len(hallway_positions), len(east_locker_hall_positions)))
