extends Node
## Verifica relieful desenat in Track13.tscn: nodurile TerrainPeak chiar ridica
## terenul, si niciunul nu calca peste sosea.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappPeaks.tscn
##
## Nu numara noduri (un nod poate exista fara ca terenul sa se miste — lectia
## `efecte-invizibile-nu-se-numara`): citeste cotele din MESH-ul de teren
## construit, care e adevarul de care se lovesc rotile.

## Cat trebuie sa urce terenul in jurul unui varf ca sa spunem ca exista.
const MIN_RISE: float = 8.0


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var peaks_node := track.get_node_or_null("Peaks")
	var specs: Array = []
	if peaks_node != null:
		for c in peaks_node.get_children():
			specs.append([c.name, c.global_position, float(c.get("radius_m"))])

	# cotele terenului, o singura trecere prin mesh-uri
	var road := PackedVector3Array()
	for p in track.baked:
		road.append(p)
	var top: Array[float] = []
	var road_delta: Array[float] = []
	top.resize(specs.size())
	road_delta.resize(specs.size())
	for i in specs.size():
		top[i] = -INF
		road_delta[i] = 0.0
	var band_worst := 0.0
	for m in _terrain_meshes(track):
		var arrays := m.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			for i in specs.size():
				var c: Vector3 = specs[i][1]
				if Vector2(v.x - c.x, v.z - c.z).length() < 25.0:
					top[i] = maxf(top[i], v.y)

	print("")
	print("=== Relieful Cappadociei — %d noduri TerrainPeak ===" % specs.size())
	var bad := 0
	for i in specs.size():
		var nm: String = specs[i][0]
		var c: Vector3 = specs[i][1]
		var r: float = specs[i][2]
		# cota soselei celei mai apropiate, ca referinta de "cat a urcat"
		var near := INF
		var near_y := 0.0
		for p in road:
			var d := Vector2(p.x - c.x, p.z - c.z).length()
			if d < near:
				near = d
				near_y = p.y
		var rise := top[i] - near_y
		var flag := ""
		if top[i] == -INF:
			flag = "  <-- terenul nu exista acolo"
			bad += 1
		elif rise < MIN_RISE:
			flag = "  <-- nu s-a ridicat (prag %.0f)" % MIN_RISE
			bad += 1
		print("  %-22s varf cerut %5.1f  teren %6.1f  sosea la %5.1f m (y %5.1f)  urcare %+6.1f%s"
			% [nm, c.y, top[i], near, near_y, rise, flag])
	print("")
	print("VERDICT: %s" % ("PROBLEMA" if bad > 0 else "OK"))
	get_tree().quit(1 if bad > 0 else 0)


func _terrain_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.mesh.get_surface_count() > 0:
			var arr := mi.mesh.surface_get_arrays(0)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if vs.size() > 1500:
				out.append(mi)
	for c in n.get_children():
		out.append_array(_terrain_meshes(c))
	return out
