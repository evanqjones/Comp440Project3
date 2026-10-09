extends SceneTree

# Inspect the finished pack, not just the editor import, before publishing it.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0]):
		push_error("Cannot mount the exported Web package.")
		quit(1)
		return
	var scene := load("res://assets/school_web.glb") as PackedScene
	if scene == null:
		push_error("The exported package is missing a loadable school scene.")
		quit(1)
		return
	var model := scene.instantiate()
	var counts := {"meshes": 0, "floors": 0, "roofs": 0, "fixtures": 0, "glass": 0}
	_count_school(model, counts)
	model.free()
	print("Exported school contents: ", counts)
	if counts.meshes < 100 or counts.floors < 10 or counts.roofs < 1 or counts.fixtures < 1 or counts.glass < 1:
		push_error("The exported school is empty or missing required environment geometry.")
		quit(1)
		return
	quit(0)

func _count_school(node: Node, counts: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh != null:
		counts.meshes += 1
		var label := String(node.name).to_lower()
		if label.contains("floor"):
			counts.floors += 1
		if label.contains("roof") or label.contains("ceiling"):
			counts.roofs += 1
		if label.contains("fluorescent -"):
			counts.fixtures += 1
		if label.contains("window glass"):
			counts.glass += 1
	for child in node.get_children():
		_count_school(child, counts)
