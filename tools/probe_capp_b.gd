extends Node
## Masuratori pentru POI B (padurea de hornuri, frac 0.04-0.18):
## (a) gabaritul fiecarui GLB din kit (inaltime reala, raza la baza),
## (b) geometria benzii pe frac: pozitie, normala laterala, latime, cota
##     terenului la 6/10/16 m in stanga si in dreapta.
## Fara cifrele astea hornurile ies plutind sau infipte in asfalt.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappB.tscn -- --track=6

const MODELS: Array[String] = [
	"rocks/chimney_a", "rocks/chimney_b", "rocks/chimney_c", "rocks/chimney_d",
	"rocks/chimney_mushroom", "rocks/chimney_triple",
	"structures/twin_chimney_gate", "buildings/dovecote",
	"buildings/cave_house_a", "buildings/cave_house_b", "buildings/cave_house_c",
	"rocks/rock_church_facade", "plants/poplar_a", "plants/poplar_b",
	"plants/shrub_dry", "plants/pigeon",
]


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== gabarite GLB (cappadocia) ===")
	for m in MODELS:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			print("  %-28s LIPSA" % m)
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		var aabb := _aabb(inst, inst.global_transform)
		print("  %-28s h=%6.2f  x=%6.2f  z=%6.2f  baza_y=%+6.2f  cx=%+5.2f cz=%+5.2f" % [
			m, aabb.size.y, aabb.size.x, aabb.size.z, aabb.position.y,
			aabb.get_center().x, aabb.get_center().z])
		inst.queue_free()

	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sampler: TrackSideSampler = track._sampler
	var n := track.baked.size()
	print("")
	print("=== banda pe POI B (n=%d puncte coapte) ===" % n)
	print("  frac      i     x        y        z      w    | sideX  sideZ | g-16  g-10  g-6  |  g+6  g+10  g+16")
	var f := 0.020
	while f <= 0.200:
		var i := int(f * float(n)) % n
		var p := track.baked[i]
		var s := track._side_at(i)
		var w := track.width_at_index(i)
		var row := "  %.3f  %4d  %8.2f %7.2f %8.2f  %4.1f | %5.2f %5.2f |" % [f, i, p.x, p.y, p.z, w, s.x, s.z]
		for d: float in [-16.0, -10.0, -6.0, 6.0, 10.0, 16.0]:
			var q: Vector3 = p + s * d
			row += " %6.2f" % sampler.ground_y(q.x, q.z)
		print(row)
		f += 0.005
	print("")
	get_tree().quit(0)


func _aabb(node: Node, root_t: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for c in _all(node):
		if c is MeshInstance3D and c.visible and c.mesh != null:
			var local := root_t.affine_inverse() * (c as MeshInstance3D).global_transform
			var b := local * (c as MeshInstance3D).mesh.get_aabb()
			if first:
				out = b
				first = false
			else:
				out = out.merge(b)
	return out


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_all(c))
	return out
