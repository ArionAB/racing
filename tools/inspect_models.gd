extends SceneTree
## Unealta temporara: masoara AABB-ul modelelor de vehicule importate,
## ca sa calibram scala si orientarea in CarData.

const MODELS: Array[String] = [
	"res://assets/models/muscle.fbx",
	"res://assets/models/police_sports.fbx",
	"res://assets/models/taxi.fbx",
	"res://assets/models/bus.fbx",
	"res://assets/models/firetruck.fbx",
]

func _init() -> void:
	for path in MODELS:
		var scene := load(path) as PackedScene
		if scene == null:
			print(path, ": NU SE INCARCA")
			continue
		var inst := scene.instantiate()
		var aabb := _merged_aabb(inst)
		print("%s\n  size=(%.2f, %.2f, %.2f) pos=(%.2f, %.2f, %.2f) copii=%d" % [
			path.get_file(), aabb.size.x, aabb.size.y, aabb.size.z,
			aabb.position.x, aabb.position.y, aabb.position.z,
			inst.get_child_count()])
		for child in inst.get_children():
			var pos_text := ""
			if child is Node3D and "wheel" in String(child.name).to_lower():
				var p := (child as Node3D).position
				pos_text = "  pos=(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
			print("    - ", child.name, pos_text)
		inst.free()
	quit()

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
