import bpy


SCHOOL_COLLECTION = "After School - School Blockout"
GLASS_COLLECTION = "School - Window Glass"
WINDOW_BOTTOM_Z = 1.15
WINDOW_TOP_Z = 2.55
WINDOW_HEIGHT_BANDS = [(1.15, 2.55), (1.4, 2.15), (4.76, 5.12)]
PANE_INSET = 0.035
PANE_DEPTH = 0.035


def make_glass_material():
	name = "Window Glass - Pale Blue"
	material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
	material.diffuse_color = (0.48, 0.72, 0.88, 0.28)
	material.use_nodes = True
	shader = material.node_tree.nodes.get("Principled BSDF")
	if shader:
		shader.inputs["Base Color"].default_value = (0.48, 0.72, 0.88, 1.0)
		shader.inputs["Alpha"].default_value = 0.28
		shader.inputs["Roughness"].default_value = 0.12
		transmission = shader.inputs.get("Transmission Weight") or shader.inputs.get("Transmission")
		if transmission:
			transmission.default_value = 0.18
	if hasattr(material, "surface_render_method"):
		material.surface_render_method = "DITHERED"
	return material


def make_pane(collection, name, center, size, material):
	cx, cy, cz = center
	sx, sy, sz = size
	verts = [
		(cx - sx / 2, cy - sy / 2, cz - sz / 2),
		(cx + sx / 2, cy - sy / 2, cz - sz / 2),
		(cx + sx / 2, cy + sy / 2, cz - sz / 2),
		(cx - sx / 2, cy + sy / 2, cz - sz / 2),
		(cx - sx / 2, cy - sy / 2, cz + sz / 2),
		(cx + sx / 2, cy - sy / 2, cz + sz / 2),
		(cx + sx / 2, cy + sy / 2, cz + sz / 2),
		(cx - sx / 2, cy + sy / 2, cz + sz / 2),
	]
	faces = [
		(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
		(1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7),
	]
	mesh = bpy.data.meshes.new(name + " Mesh")
	mesh.from_pydata(verts, [], faces)
	mesh.materials.append(material)
	obj = bpy.data.objects.new(name, mesh)
	collection.objects.link(obj)
	obj["window_glass"] = True
	return obj


school = bpy.data.collections.get(SCHOOL_COLLECTION)
if school is None:
	raise RuntimeError("Could not find the school blockout collection")

old_collection = bpy.data.collections.get(GLASS_COLLECTION)
if old_collection:
	for obj in list(old_collection.objects):
		bpy.data.objects.remove(obj, do_unlink=True)
	school.children.unlink(old_collection)
	bpy.data.collections.remove(old_collection)

glass_collection = bpy.data.collections.new(GLASS_COLLECTION)
school.children.link(glass_collection)
glass_material = make_glass_material()
pane_count = 0
created_openings = set()
wall_objects = [
	wall for wall in school.all_objects
	if wall.type == "MESH" and "wall" in wall.name.lower() and not wall.name.lower().startswith("door header")
]

for wall in wall_objects:
	world_verts = [wall.matrix_world @ vertex.co for vertex in wall.data.vertices]
	if not world_verts:
		continue
	z_levels = {round(vertex.z, 3) for vertex in world_verts}
	min_x = min(vertex.x for vertex in world_verts)
	max_x = max(vertex.x for vertex in world_verts)
	min_y = min(vertex.y for vertex in world_verts)
	max_y = max(vertex.y for vertex in world_verts)
	axis = "x" if (max_x - min_x) > (max_y - min_y) else "y"
	wall_thickness_center = (min_x + max_x) * 0.5 if axis == "y" else (min_y + max_y) * 0.5
	for bottom, top in WINDOW_HEIGHT_BANDS:
		if round(bottom, 3) not in z_levels or round(top, 3) not in z_levels:
			continue
		opening_coords = sorted({
			round(getattr(vertex, axis), 4)
			for vertex in world_verts
			if abs(vertex.z - bottom) < 0.01 or abs(vertex.z - top) < 0.01
		})
		if len(opening_coords) < 2 or len(opening_coords) % 2 != 0:
			continue
		for opening_index in range(0, len(opening_coords), 2):
			start = opening_coords[opening_index]
			end = opening_coords[opening_index + 1]
			opening_width = end - start - PANE_INSET * 2
			opening_height = top - bottom - PANE_INSET * 2
			if opening_width <= 0.1 or opening_height <= 0.1:
				continue
			along_center = (start + end) * 0.5
			if axis == "x":
				center = (along_center, wall_thickness_center, (bottom + top) * 0.5)
				size = (opening_width, PANE_DEPTH, opening_height)
			else:
				center = (wall_thickness_center, along_center, (bottom + top) * 0.5)
				size = (PANE_DEPTH, opening_width, opening_height)
			opening_key = tuple(round(value, 3) for value in (*center, *size))
			if opening_key in created_openings:
				continue
			created_openings.add(opening_key)
			name = "Window Glass - " + wall.name.replace(" - Wall", "")
			if bottom > 4.0:
				name = "Window Glass - High Exterior - " + wall.name
			elif opening_index > 0:
				name += " - %02d" % (opening_index // 2 + 1)
			make_pane(glass_collection, name, center, size, glass_material)
			pane_count += 1

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print("Added %d glass panes to existing school window openings" % pane_count)
