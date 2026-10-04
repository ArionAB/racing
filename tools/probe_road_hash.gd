extends Node
## Amprenta GEOMETRICA a soselei si a mobilierului ei, pe toate pistele: pentru
## A/B bit-identic cand se atinge `Track._build_road` / `_build_center_line` /
## `_build_kerbs` / `_build_tire_marks`.
##
## ProbeTheme numara noduri si probe_decor numara materiale/triunghiuri, dar
## niciuna nu vede O CULOARE DE VERTEX schimbata sau un UV mutat — exact ce poate
## strica o refactorizare a benzii soselei fara sa schimbe un singur numar.
## Aici fiecare MeshInstance3D copil direct al pistei (soseaua, fustele, linia de
## mijloc, bordurile, urmele, umerii...) isi hash-uieste TOATE tablourile de
## varfuri (pozitie, normala, culoare, UV, UV2, indici), iar materialele
## ShaderMaterial isi tiparesc parametrii.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRoadHash.tscn > dupa.txt
##   (acelasi lucru pe baza, apoi `diff` — trebuie sa fie gol)
##
## Rulata ca SCENA (autoload-uri), ca ProbeTheme.
##
## `-- --dirt=0.2,0.4` pune acel interval de pamant pe toate pistele care il
## accepta: e SABOTAJUL probei — amprenta trebuie sa se schimbe (soseaua, linia,
## bordurile, urmele). Daca nu se schimba, proba nu vede ce trebuie sa vada.

func _ready() -> void:
	await get_tree().process_frame
	var dirt: Array[Vector2] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dirt="):
			var p := arg.trim_prefix("--dirt=").split(",")
			dirt.append(Vector2(float(p[0]), float(p[1])))
	for i in GameState.TRACK_SCENES.size():
		var scene := load(GameState.TRACK_SCENES[i]) as PackedScene
		var track := scene.instantiate() as Track
		if not dirt.is_empty() and "custom_dirt_ranges" in track:
			track.set("custom_dirt_ranges", dirt)
		get_tree().root.add_child(track)
		await get_tree().process_frame
		await get_tree().process_frame
		_dump(i, track)
		track.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _dump(idx: int, track: Track) -> void:
	print("=== %s  %s ===" % [
		GameState.TRACK_SCENES[idx].get_file().get_basename(), track.track_name])
	var rows := 0
	for n in track.get_children():
		var inst := n as MeshInstance3D
		if inst == null or inst.mesh == null:
			continue
		var h := 0
		var verts := 0
		for s in inst.mesh.get_surface_count():
			var arrays := inst.mesh.surface_get_arrays(s)
			for a in arrays.size():
				if arrays[a] != null:
					h = hash([h, a, hash(arrays[a])])
			var v := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			verts += v.size() if v != null else 0
		# Numele auto-generate (@MeshInstance3D@123) depind de ordinea de creare:
		# raportam tipul + materialul, nu numele, dar pastram numele explicite.
		var nm := String(inst.name)
		if nm.begins_with("@"):
			nm = "(fara nume)"
		print("  %-22s verts %7d  hash %d  %s" % [nm, verts, h, _material_sig(inst.material_override)])
		rows += 1
	# Un rand de coliziune per corp static, ca sa se vada si fizica soselei.
	for n in track.get_children():
		var body := n as StaticBody3D
		if body == null:
			continue
		var h := 0
		var tris := 0
		for c in body.get_children():
			var cs := c as CollisionShape3D
			if cs != null and cs.shape is ConcavePolygonShape3D:
				var faces := (cs.shape as ConcavePolygonShape3D).get_faces()
				h = hash([h, hash(faces)])
				tris += faces.size() / 3
		print("  corp %-18s tris %7d  hash %d" % [String(body.name).substr(0, 18), tris, h])
		rows += 1
	if rows == 0:
		print("  EROARE: nicio masuratoare pe aceasta pista")


func _material_sig(m: Material) -> String:
	if m == null:
		return "-"
	if m is ShaderMaterial:
		var sm := m as ShaderMaterial
		var parts: Array[String] = [sm.shader.resource_path.get_file() if sm.shader != null else "?"]
		if sm.shader != null:
			for u in sm.shader.get_shader_uniform_list():
				var uname := String(u["name"])
				var val: Variant = sm.get_shader_parameter(uname)
				if val is Texture2D:
					parts.append("%s=%s" % [uname, (val as Texture2D).resource_path.get_file()])
				else:
					parts.append("%s=%s" % [uname, str(val)])
		return " ".join(parts)
	if m is StandardMaterial3D:
		var st := m as StandardMaterial3D
		return "std %s %s r%.2f" % [st.albedo_color.to_html(true),
			st.albedo_texture.resource_path.get_file() if st.albedo_texture != null else "-", st.roughness]
	return m.get_class()
