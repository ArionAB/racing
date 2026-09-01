extends Node
## FATETE: mesh-ul chiar ajunge deindexat la randare?
##
## Trei runde de "am reparat, dar poza e identica" au venit din deductii pe cod
## (GLB -> ChimneyShape -> world_prop). Sonda asta nu deduce: incarca Track13,
## gaseste MeshInstance3D-urile hornurilor si masoara pe mesh-ul VIU raportul
## vertecsi/triunghiuri. Indexat = vertecsii se impart (raport ~0.5-1), deci
## normale mediate = smooth. Deindexat = 3 vertecsi per triunghi (raport 3.0),
## deci normale pe fata = fatete.
func _ready() -> void:
	var scn := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var root := scn.instantiate()
	# add_child direct in _ready pica ("parent busy setting up children"),
	# si atunci NIMIC nu intra in arbore: probele arata mesh-ul brut din GLB
	# si par sa dovedeasca "fixul nu se aplica". Deferred + doua cadre.
	get_tree().root.add_child.call_deferred(root)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var meshes: Array[MeshInstance3D] = []
	_collect(root, meshes)
	var seen := {}
	for mi in meshes:
		var nm := mi.name.to_lower()
		var par := mi.get_parent()
		var pn: String = (String(par.name) if par != null else "").to_lower()
		if not (nm.contains("chimney") or pn.contains("chimney")
				or nm.contains("horn") or pn.contains("ch_")):
			continue
		var m := mi.mesh
		if m == null: continue
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var nv: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var idx = arr[Mesh.ARRAY_INDEX]
			var ni: int = (idx as PackedInt32Array).size() if idx != null else 0
			var tris: int = (ni / 3) if ni > 0 else (nv / 3)
			var ratio := float(nv) / maxf(float(tris), 1.0)
			var key := "%s|s%d" % [pn + "/" + nm, s]
			if seen.has(key): continue
			seen[key] = true
			print("%-46s vert=%5d tri=%5d  vert/tri=%.2f  %s  index=%s" % [
				key, nv, tris, ratio,
				("FATETAT" if ratio > 2.5 else "NETED"),
				("da" if ni > 0 else "nu")])
	print("total mesh-uri de horn inspectate: %d" % seen.size())
	get_tree().quit()

func _collect(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
