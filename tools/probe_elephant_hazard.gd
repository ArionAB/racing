extends Node
## SONDA TEMPORARA (lot elefanti-hazard, Track14): verifica prin instantiere
## headless daca G_Elefant1/G_Elefant2 (SlidingHazard, kind=SLIDING) au primit
## clasa elephant_hide SI daca proiectia e in spatiul OBIECTULUI (nu al lumii).
##
## Nu foloseste captura de ecran (interzisa in sesiunea asta): tipareste, per
## MeshInstance3D din fiecare hazard, numele nodului, textura din
## material_override si uv1_triplanar/uv1_world_triplanar/uv1_scale.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeElephantHazard.tscn -- --track=14

func _ready() -> void:
	await get_tree().process_frame
	var only := 14
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	var idx := GameState.resolve_track_index(only)
	if idx < 0:
		push_error("ProbeElephantHazard: track invalid")
		get_tree().quit(1)
		return
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var t := scene.instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame
	for i in 8:
		await get_tree().physics_frame

	var hazards: Array[Node] = []
	_collect_sliding(t, hazards)
	print("=== PROBE ELEPHANT HAZARD — %s ===" % GameState.track_label(only))
	print("SlidingHazard gasite: %d" % hazards.size())
	var checked := 0
	for h in hazards:
		var name_ok := String(h.name).begins_with("G_Elefant") \
			or String(h.name).find("Elefant") >= 0
		# Nu filtram STRICT dupa nume (SlidingHazard e instantiat direct de
		# Track, numele nodului poate fi generic) — filtram dupa modelul chiar
		# incarcat: cauta un MeshInstance3D cu nume care incepe cu "Elephant".
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(h, meshes)
		var is_elephant := false
		for mi in meshes:
			if String(mi.name).begins_with("Elephant"):
				is_elephant = true
				break
		if not is_elephant:
			continue
		checked += 1
		print("--- hazard node: %s (scene name=%s, global_pos=%s, model_scale=%s) ---"
			% [h.name, name_ok, h.global_position, h.get("model_scale")])
		for mi in meshes:
			var mat := mi.material_override
			var tex_path := "<none>"
			var tri := "n/a"
			var world_tri := "n/a"
			var scale_str := "n/a"
			if mat != null and mat is StandardMaterial3D:
				var sm := mat as StandardMaterial3D
				if sm.albedo_texture != null:
					tex_path = sm.albedo_texture.resource_path
				tri = str(sm.uv1_triplanar)
				world_tri = str(sm.uv1_world_triplanar)
				scale_str = str(sm.uv1_scale)
			print("  mesh=%s  tex=%s  uv1_triplanar=%s  uv1_world_triplanar=%s  uv1_scale=%s"
				% [mi.name, tex_path, tri, world_tri, scale_str])
	if checked == 0:
		print("PICAT: niciun hazard elefant gasit — sonda nu a masurat nimic.")
		get_tree().quit(1)
		return
	get_tree().quit(0)


func _collect_sliding(node: Node, out: Array[Node]) -> void:
	if node.get_class() == "AnimatableBody3D" and node.get_script() != null \
			and String(node.get_script().resource_path).ends_with("sliding_hazard.gd"):
		out.append(node)
	for c in node.get_children():
		_collect_sliding(c, out)


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for c in node.get_children():
		_collect_meshes(c, out)
