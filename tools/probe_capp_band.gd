extends Node
## Gabaritul pieselor de faleza/mesa, ca sa se poata compune un PERETE continuu.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappBand.tscn

const MODELS: Array[String] = [
	"rocks/cliff_band_module", "rocks/red_mesa",
	"rocks/chimney_a", "rocks/chimney_b", "rocks/chimney_c", "rocks/chimney_d",
	"rocks/chimney_mushroom", "rocks/chimney_triple",
	"rocks/cracked_chimney_a", "rocks/cracked_chimney_b", "rocks/cracked_chimney_c",
	"plants/poplar_a", "plants/poplar_b",
]

func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== gabarite pentru peretele de orizont ===")
	for m in MODELS:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			print("  %-30s LIPSA" % m); continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		var aabb := _aabb(inst, inst.global_transform)
		print("  %-30s h=%6.2f  x=%6.2f  z=%6.2f  y0=%+6.2f" % [
			m, aabb.size.y, aabb.size.x, aabb.size.z, aabb.position.y])
		inst.queue_free()
	print("")
	get_tree().quit(0)

func _aabb(node: Node, root_t: Transform3D) -> AABB:
	var out := AABB(); var first := true
	for c in _all(node):
		if c is MeshInstance3D and c.visible and c.mesh != null:
			var b := (root_t.affine_inverse() * (c as MeshInstance3D).global_transform) * (c as MeshInstance3D).mesh.get_aabb()
			if first: out = b; first = false
			else: out = out.merge(b)
	return out

func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children(): out.append_array(_all(c))
	return out
