extends Node
## Ce ramane NOD de mesh in DecorManual dupa coacere, pe model, cu numarul de
## niveluri LOD, materialul si daca e triplanar (= de ce n-a intrat in buffer).
## Prinde clasa de accident „mesh reconstruit fara LOD-uri" (memoria
## lod-pierdut-la-reconstruirea-mesh-ului): un model cu `lod0` si mii de
## triunghiuri se deseneaza intreg la orice distanta.
##   godot --headless --path . res://tools/ProbeLodNodes.tscn -- --track=17
## (--track = NUMARUL de scena, ca la ProbePerf; implicit 17 = Jodhpur)
func _ready() -> void:
	var track_no := 17
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			track_no = int(a.trim_prefix("--track="))
	var scene := load("res://scenes/tracks/Track%02d.tscn" % track_no) as PackedScene
	if scene == null:
		print("ProbeLodNodes: nu exista Track%02d" % track_no)
		get_tree().quit(2)
		return
	var track := scene.instantiate()
	add_child(track)
	for i in 12:
		await get_tree().process_frame
	var dm := track.get_node_or_null("DecorManual")
	if dm == null:
		print("ProbeLodNodes: pista n-are DecorManual")
		get_tree().quit(2)
		return
	var by_model := {}
	var dumped := 0
	for n in dm.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.visible or not mi.is_visible_in_tree():
			continue
		# radacina GLB
		var p: Node = mi
		var glb := ""
		while p != null and p != dm:
			if p.scene_file_path != "":
				glb = p.scene_file_path.get_file(); break
			p = p.get_parent()
		var lods := 0
		var tris := 0
		for s in mi.mesh.get_surface_count():
			var d := RenderingServer.mesh_get_surface(mi.mesh.get_rid(), s)
			lods += (d.get("lods", []) as Array).size()
			var arr := mi.mesh.surface_get_arrays(s)
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			tris += ((idx as PackedInt32Array).size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		var key := "%s|%s|lod%d|ovr:%s|tri:%s" % [glb, mi.mesh.get_class(), lods, 
			(mi.material_override.get_class() if mi.material_override else "null"), 
			"tri" if (mi.material_override is StandardMaterial3D and ((mi.material_override as StandardMaterial3D).uv1_world_triplanar)) else "no"]
		if not by_model.has(key):
			by_model[key] = {"n": 0, "tris": 0}
		by_model[key]["n"] += 1
		by_model[key]["tris"] += tris
		# Exemple: mesh-uri din cod (fara GLB) sau fara LOD, grele.
		if lods == 0 and tris > 2000 and dumped < 8:
			dumped += 1
			print("FARA_LOD %s tris=%d mesh=%s override=%s" % [mi.get_path(), tris, mi.mesh.get_class(), mi.material_override.get_class() if mi.material_override else "null"])
	var keys := by_model.keys()
	keys.sort()
	for k in keys:
		print("%-70s n=%4d tris_total=%d" % [k, by_model[k]["n"], by_model[k]["tris"]])
	get_tree().quit()
