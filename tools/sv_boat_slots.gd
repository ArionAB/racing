extends SceneTree
## Sonda temporara: lista nodurile Boat din cruise_boat.glb (brut) SI din
## instanta reala trasa in Track16.tscn (cruiseBoatDock4/5), cu materialul
## fiecarui MeshInstance3D dupa ce world_prop.gd si-a facut treaba (clase,
## remap de sloturi). Scop: gasi cauza "carena alba citeste ca lemn" —
## verdict runda 3 pe POI A.

func _init() -> void:
	print("=== GLB brut: cruise_boat.glb ===")
	var glb: PackedScene = load("res://assets/models/fiordland/vehicles/cruise_boat.glb")
	var inst := glb.instantiate()
	_dump(inst, 0)
	inst.free()

	print("\n=== Instanta reala din Track16.tscn ===")
	var track_scene: PackedScene = load("res://scenes/tracks/Track16.tscn")
	var track := track_scene.instantiate()
	get_root().add_child(track)
	await process_frame
	await process_frame
	await process_frame
	var zone := track.get_node_or_null("DecorManual/ZoneA_Chei")
	if zone == null:
		print("ZoneA_Chei NU exista")
		quit(1)
		return
	for child in zone.get_children():
		if str(child.name).begins_with("cruiseBoatDock"):
			print("--- %s ---" % child.name)
			_dump(child, 0)
	quit(0)


func _dump(node: Node, depth: int) -> void:
	var pad := "  ".repeat(depth)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		var nsurf := mesh.get_surface_count() if mesh != null else 0
		print("%s[Mesh] %s  surfaces=%d" % [pad, node.name, nsurf])
		for si in range(nsurf):
			var mat: Material = mi.get_surface_override_material(si)
			var src_mat: Material = mesh.surface_get_material(si) if mesh != null else null
			var eff: Material = mat if mat != null else src_mat
			var tex_path := "-"
			var albedo := "-"
			if eff is StandardMaterial3D:
				var sm := eff as StandardMaterial3D
				if sm.albedo_texture != null:
					tex_path = sm.albedo_texture.resource_path
				albedo = str(sm.albedo_color)
			elif eff is ShaderMaterial:
				tex_path = "[ShaderMaterial] " + str((eff as ShaderMaterial).shader.resource_path)
			print("%s    surf%d: mat=%s override=%s tex=%s albedo=%s" % [
				pad, si, eff, (mat != null), tex_path, albedo])
	else:
		print("%s%s (%s)" % [pad, node.name, node.get_class()])
	for c in node.get_children():
		_dump(c, depth + 1)
