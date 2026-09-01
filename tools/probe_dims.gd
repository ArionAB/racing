extends Node
## Ce slot poarta POALELE cojii (y sub 14, raza mare)? Ala e portocaliul de jos.
func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D: out.append(n)
	for c in n.get_children(): _collect(c, out)
func _ready() -> void:
	var ps := load("res://assets/models/cappadocia/structures/hollow_rock.glb") as PackedScene
	var inst := ps.instantiate() as Node3D
	add_child(inst); await get_tree().process_frame
	var mis: Array = []; _collect(inst, mis)
	for mi: MeshInstance3D in mis:
		var arr := mi.mesh.surface_get_arrays(0)
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var vt: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var hist := {}
		for i in uv.size():
			# poalele in coordonate LOCALE: y < 2.5 (scalat 1.6 -> 4 m)
			if vt[i].y < 2.5 and Vector2(vt[i].x, vt[i].z).length() > 24.0:
				var s := int(floor(uv[i].x * 32.0))
				hist[s] = int(hist.get(s,0)) + 1
		var k := hist.keys(); k.sort()
		print("sloturi in POALE (y_local<2.5, r_local>24):")
		for kk in k: print("   slot %2d : %d vertecsi" % [kk, hist[kk]])
	get_tree().quit()
