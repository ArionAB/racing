extends Node
## Ce mesh VIZIBIL taie drumul, fara sa se bazeze pe coliziunea lui: fiecare
## mesh vizibil (si fiecare instanta MultiMesh) aflat la sub `--radius` m de
## zona primeste temporar un colizor exact (trimesh) pe un strat propriu, apoi
## se trag raze ORIZONTALE peste latimea drumului, la 0,5 / 1,0 / 1,5 m peste
## axa, la fiecare punct copt din intervalul de fractii. Se raporteaza nodul
## lovit si daca in acelasi loc exista si un corp fizic real (strat 1).
##   godot --headless --path . res://tools/ProbeRoadRaypick.tscn -- --track=6 --frac=0.985,1.0

const PICK_LAYER := 1 << 20

var _f0 := 0.0
var _f1 := 1.0
var _radius := 60.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			var p := arg.trim_prefix("--frac=").split(",")
			_f0 = float(p[0])
			_f1 = float(p[1])
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().physics_frame
	var r: TrackRoute = track.route_at(0)
	var idxs: Array[int] = []
	for i in r.baked.size():
		var f := track.frac_at(i)
		if f >= _f0 and f <= _f1:
			idxs.append(i)
	if idxs.is_empty():
		get_tree().quit(1)
		return
	# Tubul drumului pe interval (0,3..1,6 m peste axa, latimea intreaga): doar
	# piesele a caror cutie il atinge primesc colizor — trimesh pe tot ce e la
	# 60 m (teren, pereti) nu termina in 15 minute.
	var tubes: Array[AABB] = []
	for i in idxs:
		var hw := track.width_at_index(i)
		tubes.append(AABB(r.baked[i] + Vector3(-hw, 0.3, -hw), Vector3(hw * 2.0, 1.3, hw * 2.0)))
	var holder := Node3D.new()
	get_tree().root.add_child(holder)
	var made := 0
	for node in track.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var wb := mi.global_transform * mi.get_aabb()
		if not _touches(wb, tubes):
			continue
		made += _pick_body(holder, mi.mesh, mi.global_transform, String(track.get_path_to(mi)))
	for node in track.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		var mm := mmi.multimesh
		if mm == null or mm.mesh == null or not mmi.is_visible_in_tree():
			continue
		for k in mm.instance_count:
			var xf := mmi.global_transform * mm.get_instance_transform(k)
			if not _touches(xf * mm.mesh.get_aabb(), tubes):
				continue
			made += _pick_body(holder, mm.mesh, xf, "%s #%d" % [track.get_path_to(mmi), k])
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("[raypick] %d colizori temporari, %d puncte de drum" % [made, idxs.size()])
	var space := track.get_world_3d().direct_space_state
	var hits: Dictionary = {}
	for i in idxs:
		var p := r.baked[i]
		var side := r.side_at(i)
		var hw := track.width_at_index(i)
		for h: float in [0.5, 1.0, 1.5]:
			for dir: float in [1.0, -1.0]:
				var a := p + Vector3.UP * h - side * dir * (hw + 0.5)
				var b := p + Vector3.UP * h + side * dir * (hw + 0.5)
				var q := PhysicsRayQueryParameters3D.create(a, b, PICK_LAYER)
				q.hit_from_inside = true
				var hit := space.intersect_ray(q)
				if not hit.is_empty():
					var col := hit.collider as Node
					var src := String(col.get_meta("src", col.name))
					var pos := hit.position as Vector3
					var real := PhysicsRayQueryParameters3D.create(a, b, 1)
					var rh := space.intersect_ray(real)
					var real_name := "NICIUNUL" if rh.is_empty() else String((rh.collider as Node).name)
					var key := src
					if not hits.has(key):
						hits[key] = "frac %.3f  h %.1f  lateral %+.1f  corp real pe aceeasi raza: %s" % [
							track.frac_at(i), h, (pos - p).dot(side), real_name]
	print("[raypick] %d surse lovite:" % hits.size())
	for k in hits:
		print("  %s\n      %s" % [k, hits[k]])
	get_tree().quit(0)


func _touches(b: AABB, tubes: Array[AABB]) -> bool:
	for t in tubes:
		if b.intersects(t):
			return true
	return false


func _pick_body(holder: Node3D, mesh: Mesh, xf: Transform3D, src: String) -> int:
	var shape := mesh.create_trimesh_shape()
	if shape == null:
		return 0
	var body := StaticBody3D.new()
	body.collision_layer = PICK_LAYER
	body.collision_mask = 0
	body.set_meta("src", src)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	holder.add_child(body)
	body.global_transform = xf
	return 1
