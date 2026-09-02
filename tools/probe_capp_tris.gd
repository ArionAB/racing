extends Node
## Triunghiuri per piesa de kit, ca sa nu repetam accidentul de pe POI B
## (un ciob de 20 cm care instantiaza un mesh de 2530 tri). Se citeste
## INAINTE de a alege ce se multiplica, nu dupa ce pista sare la 581k.
##   godot --headless --path . res://tools/ProbeCappTris.tscn

const MODELS: Array[String] = [
	"buildings/cave_house_a", "buildings/cave_house_b", "buildings/cave_house_c",
	"buildings/dovecote", "buildings/farmhouse",
	"props/carpet_terrace", "props/pottery_cart", "props/pot_stack", "props/torch",
	"plants/poplar_a", "plants/poplar_b", "plants/shrub_dry", "plants/pigeon",
	"plants/vine_row",
	"rocks/chimney_a", "rocks/chimney_b", "rocks/chimney_c", "rocks/chimney_d",
	"rocks/chimney_mushroom", "rocks/chimney_triple",
	"rocks/cracked_chimney_a", "rocks/cracked_chimney_b", "rocks/cracked_chimney_c",
	"rocks/rock_church_facade",
	"structures/cave_entrance", "structures/church_arch",
]


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== triunghiuri per piesa (POI A) ===")
	var rows: Array = []
	for m in MODELS:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		rows.append([m, _tris(inst)])
		inst.queue_free()
	rows.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
	for r in rows:
		print("  %-28s %7d tri" % [r[0], r[1]])
	get_tree().quit(0)


func _tris(node: Node) -> int:
	var t := 0
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			for si in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(si)
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				if idx.size() > 0:
					t += idx.size() / 3
				else:
					t += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	for c in node.get_children():
		t += _tris(c)
	return t
