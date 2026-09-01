extends SceneTree
## Lipeste prop-urile din Zone05_Vineyard de teren: rescrie Y-ul din .tscn cu
## cota reala a terenului sub fiecare. Sonda a gasit 11 prop-uri ingropate
## (BalloonStanding2 la -22 m) fiindca asezarea folosea cota de la AX, iar
## dealul din stanga urca. Rulare unica, ca unealta:
##
##   godot --headless --path . --script res://tools/snap_poi_e.gd


func _init() -> void:
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	root.add_child(track)
	await process_frame
	await process_frame

	var tv := PackedVector3Array()
	for m in _terrain(track):
		var mi := m as MeshInstance3D
		var xf := mi.global_transform
		for v in (mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			tv.append(xf * v)

	var zone := track.find_child("Zone05_Vineyard", true, false)
	var fixes := {}
	for c in zone.get_children():
		if String(c.name).ends_with("_col"):
			continue
		var n3 := c as Node3D
		if n3 == null:
			continue
		var p := n3.global_position
		var best := 64.0
		var gy := NAN
		for v in tv:
			var d := Vector2(v.x - p.x, v.z - p.z).length_squared()
			if d < best:
				best = d
				gy = v.y
		if not is_nan(gy) and absf(p.y - gy) > 0.25:
			fixes[String(c.name)] = gy
	print("de corectat: %d" % fixes.size())

	var path := "res://scenes/tracks/Track13.tscn"
	var f := FileAccess.open(path, FileAccess.READ)
	var lines := f.get_as_text().split("\n")
	f.close()
	var cur := ""
	for i in lines.size():
		var l := lines[i]
		if l.begins_with("[node name=\""):
			cur = l.substr(12, l.find("\"", 12) - 12)
		elif l.begins_with("transform = Transform3D(") and fixes.has(cur):
			var inner := l.substr(l.find("(") + 1, l.rfind(")") - l.find("(") - 1)
			var parts := inner.split(",")
			parts[10] = " %.3f" % float(fixes[cur])
			lines[i] = "transform = Transform3D(%s)" % ",".join(parts)
	var w := FileAccess.open(path, FileAccess.WRITE)
	w.store_string("\n".join(lines))
	w.close()
	print("scris.")
	quit()


func _terrain(root_n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root_n is MeshInstance3D and (root_n as MeshInstance3D).mesh != null:
		var nm := String(root_n.name).to_lower()
		if not (nm.contains("road") or nm.contains("vine") or nm.contains("poplar")
				or nm.contains("farm") or nm.contains("balloon")):
			out.append(root_n)
	for c in root_n.get_children():
		if String(c.name) != "DecorManual":
			out.append_array(_terrain(c))
	return out
