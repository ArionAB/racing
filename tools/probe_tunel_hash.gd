extends Node
## Amprenta tuburilor de tunel (TunnelBore / TunnelPortal) si a materialelor lor,
## pe pistele date: dovada de BIT-IDENTITATE cand se atinge `Track._build_tunnel`
## (Carrara: tub fara autocar, clasa de material pe tunel). Rulata inainte si dupa o
## schimbare, aceeasi comanda, aceleasi cifre = pistele existente nu s-au miscat.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTunelHash.tscn -- --scenes=16,21
##
## `--scenes=` ia NUMERE DE SCENA (Track16.tscn, Track21.tscn), nu pozitii din lista.

func _ready() -> void:
	await get_tree().process_frame
	var nums: PackedStringArray = ["16", "21"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenes="):
			nums = arg.trim_prefix("--scenes=").split(",")
	for num in nums:
		var path := "res://scenes/tracks/Track%02d.tscn" % int(num)
		var scene := load(path) as PackedScene
		var track := scene.instantiate() as Track
		get_tree().root.add_child(track)
		await get_tree().process_frame
		await get_tree().process_frame
		print("=== %s (%s) ===" % [path.get_file(), track.track_name])
		var total := PackedByteArray()
		var count := 0
		for ci in track.get_child_count():
			var body := track.get_child(ci) as StaticBody3D
			if body == null:
				continue
			var nm := String(body.name)
			if not (nm.begins_with("TunnelBore") or nm.begins_with("TunnelPortal")):
				continue
			count += 1
			# Geometria = fetele trimesh-ului de coliziune (acelasi ArrayMesh ca vizualul);
			# materialul = al MeshInstance3D-ului adaugat chiar inainte de corp.
			var cs := body.get_child(0) as CollisionShape3D
			var buf := var_to_bytes((cs.shape as ConcavePolygonShape3D).get_faces())
			var mdesc := "none"
			var mi := track.get_child(ci - 1) as MeshInstance3D if ci > 0 else null
			if mi != null:
				var vc := PackedByteArray()
				var mesh := mi.mesh
				for sidx in mesh.get_surface_count():
					var arrays := mesh.surface_get_arrays(sidx)
					for k in [Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR]:
						if arrays[k] != null:
							vc.append_array(var_to_bytes(arrays[k]))
				buf.append_array(vc)
				var mat := mi.material_override
				if mat is StandardMaterial3D:
					var sm := mat as StandardMaterial3D
					var tex_md5 := "-"
					if sm.albedo_texture != null and sm.albedo_texture.get_image() != null:
						tex_md5 = sm.albedo_texture.get_image().get_data().hex_encode().md5_text()
					mdesc = "tex=%s uv1=%s col=%s" % [tex_md5, sm.uv1_scale,
						sm.albedo_color.to_html()]
			total.append_array(buf)
			print("  %s  fete=%d  md5=%s  mat[%s]" % [nm,
				(cs.shape as ConcavePolygonShape3D).get_faces().size() / 3,
				buf.hex_encode().md5_text(), mdesc])
		print("  piese: %d   amprenta totala: %s" % [count, total.hex_encode().md5_text()])
		track.queue_free()
		await get_tree().process_frame
	get_tree().quit()
