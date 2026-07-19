extends SceneTree
## Unealta: masoara modelele GLB (dimensiuni + structura + originea).

const MODELS: Array[String] = [
	"res://assets/models/toy_dino.glb",
	"res://assets/models/sandbox_border.glb",
	"res://assets/models/rocks.glb",
]

func _init() -> void:
	for path in MODELS:
		var scene := load(path) as PackedScene
		if scene == null:
			print(path.get_file(), ": NU SE INCARCA")
			continue
		var inst := scene.instantiate()
		var aabb := _merged_aabb(inst)
		print("%s  size=(%.2f, %.2f, %.2f) pos=(%.2f, %.2f, %.2f)" % [
			path.get_file(), aabb.size.x, aabb.size.y, aabb.size.z,
			aabb.position.x, aabb.position.y, aabb.position.z])
		_print_tree(inst, "  ")
		inst.free()
	quit()

func _print_tree(node: Node, indent: String) -> void:
	for child in node.get_children():
		print(indent, "- ", child.name, " (", child.get_class(), ")")
		if indent.length() < 8:
			_print_tree(child, indent + "  ")

func _merged_aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		var mesh_inst := current as MeshInstance3D
		if mesh_inst != null:
			var local := mesh_inst.get_aabb()
			var xform: Transform3D = mesh_inst.transform
			var parent := mesh_inst.get_parent()
			while parent != null and parent is Node3D and parent != node:
				xform = (parent as Node3D).transform * xform
				parent = parent.get_parent()
			var transformed := xform * local
			if first:
				result = transformed
				first = false
			else:
				result = result.merge(transformed)
		for child in current.get_children():
			stack.push_back(child)
	return result
