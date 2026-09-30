extends Node
## Amprenta SUPRAFETELOR construite de track.gd (nu doar a cotelor, ca
## SvGroundHash): geometria + vertex color + UV-urile mesh-urilor de teren,
## umeri, sosea si apa, plus proprietatile materialelor lor. Dovada de
## neutralitate pentru chei de tema opt-in care schimba CULOAREA sau
## MATERIALUL, nu relieful (jodhpur/poi-sol: sol pe zone, pavaj, asfalt, apa).
##
##   godot --headless --path . res://tools/SvSurfaceHash.tscn -- --scenes=09,11,13,16
##
## Acelasi hash inainte si dupa = pista nu vede schimbarea.

func _ready() -> void:
	var scenes := ["09", "11", "13", "16"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenes="):
			scenes = Array(arg.trim_prefix("--scenes=").split(","))
	for s in scenes:
		var ps := load("res://scenes/tracks/Track%s.tscn" % s) as PackedScene
		var tr := ps.instantiate() as Node3D
		add_child(tr)
		for k in 3:
			await get_tree().process_frame
		var parts := PackedStringArray()
		var n_mesh := 0
		for node in _walk(tr):
			if not (node is MeshInstance3D):
				continue
			var nm := String(node.name)
			# Soseaua si umerii ies din _add_mesh_with_collision fara nume
			# (`@MeshInstance3D@N`, instabil intre rulari): intra toate
			# mesh-urile, cu numele automat inlocuit de "anon".
			if nm.begins_with("@"):
				nm = "anon"
			n_mesh += 1
			var mi := node as MeshInstance3D
			var h := nm
			if mi.mesh != null:
				for si in mi.mesh.get_surface_count():
					var arr := mi.mesh.surface_get_arrays(si)
					for a in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR,
							Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_INDEX]:
						var v = arr[a]
						h += "|" + (var_to_bytes(v).hex_encode().sha256_text().left(12) if v != null else "-")
					h += "|m:" + _mat_sig(mi.mesh.surface_get_material(si))
			h += "|o:" + _mat_sig(mi.material_override)
			parts.append(h)
		parts.sort()
		print("Track%s  suprafete[%d] %s" % [s, n_mesh, "\n".join(parts).sha256_text().left(16)])
		for p in parts:
			print("    ", p.left(40), " ", p.sha256_text().left(12))
		tr.queue_free()
		await get_tree().process_frame
	get_tree().quit(0)


func _mat_sig(m: Material) -> String:
	if m == null:
		return "-"
	var sig := m.get_class()
	if m is StandardMaterial3D:
		var sm := m as StandardMaterial3D
		sig += "%s|%s|%s|%.3f" % [sm.albedo_color.to_html(true),
			sm.albedo_texture.resource_path if sm.albedo_texture else "",
			sm.detail_albedo.resource_path if sm.detail_albedo else "", sm.roughness]
	elif m is ShaderMaterial:
		var shm := m as ShaderMaterial
		sig += shm.shader.resource_path if shm.shader else ""
		for u in shm.shader.get_shader_uniform_list() if shm.shader else []:
			var val = shm.get_shader_parameter(u["name"])
			if val is Texture2D:
				sig += "|%s=%s" % [u["name"], (val as Texture2D).resource_path]
			else:
				sig += "|%s=%s" % [u["name"], str(val)]
	return sig.sha256_text().left(10)


func _walk(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children():
		out.append_array(_walk(c))
	return out
