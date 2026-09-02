extends Node
## Cota reala a terenului SUB fiecare prop din Zone05_Vineyard, si cat e
## suspendat/ingropat. Vederea de sus a aratat ferma plutind pe coasta si un
## balon infipt in deal — asezarea folosea cota de la AX, dar dealul urca.


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	# toti vertecsii de teren, o data
	var tv := PackedVector3Array()
	for m in _terrain(track):
		var mi := m as MeshInstance3D
		var xf := mi.global_transform
		for v in (mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			tv.append(xf * v)

	var zone := track.find_child("Zone05_Vineyard", true, false)
	print("")
	print("=== Cota terenului sub prop-uri (%d vertecsi de teren) ===" % tv.size())
	print("nume                 y_prop   teren   delta   verdict")
	var bad := 0
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
		if is_nan(gy):
			continue
		var delta := p.y - gy
		var verdict := "ok"
		if delta > 1.2:
			verdict = "PLUTESTE"
			bad += 1
		elif delta < -1.2:
			verdict = "INGROPAT"
			bad += 1
		if verdict != "ok" or String(c.name).begins_with("Farm") or String(c.name).begins_with("Balloon"):
			print("%-20s %6.2f  %6.2f  %+6.2f   %s" % [c.name, p.y, gy, delta, verdict])
	print("")
	print("prop-uri gresite: %d" % bad)
	get_tree().quit()


func _terrain(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		var nm := String(root.name).to_lower()
		if not (nm.contains("road") or nm.contains("vine") or nm.contains("poplar")
				or nm.contains("farm") or nm.contains("balloon")):
			out.append(root)
	for c in root.get_children():
		if String(c.name) != "DecorManual":
			out.append_array(_terrain(c))
	return out
