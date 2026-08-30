extends Node
## CE se randeaza in coltul din dreapta-jos: se intreaba RAZELE, nu lista de noduri.
##
## ProbeInFrame (cu camera potrivita pe snapshot.gd) nu gaseste NIMIC acolo, dar
## in imagine coltul e plin de forme colorate. Cand sonda si imaginea nu sunt de
## acord, imaginea are dreptate — deci trag raze prin pixelii aia si intreb ce
## corp ating.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRAC: float = 0.245


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var i := int(FRAC * float(n)) % n
	var p := s.baked_point(i)
	var dir := (s.baked_point((i + 12) % n) - p).normalized()
	var eye := p - dir * 7.5 + Vector3.UP * 3.2
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 68.0
	cam.far = 400.0
	cam.look_at_from_position(eye, p + dir * 14.0 + Vector3.UP * 1.2, Vector3.UP)
	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var space := get_viewport().world_3d.direct_space_state
	var seen := {}
	for gx in 9:
		for gy in 6:
			var u := 0.62 + 0.36 * float(gx) / 8.0
			var v := 0.50 + 0.46 * float(gy) / 5.0
			var sp := Vector2(u * vp.x, v * vp.y)
			var from := cam.project_ray_origin(sp)
			var to := from + cam.project_ray_normal(sp) * 400.0
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
			if hit.is_empty():
				continue
			var col := hit["collider"] as Node
			var nm := String(col.name)
			var par := col.get_parent()
			if par != null:
				nm = String(par.name) + "/" + nm
			seen[nm] = int(seen.get(nm, 0)) + 1
	print("=== ce ating razele in coltul jos-dreapta ===")
	for k in seen:
		print("  %-46s %d raze" % [k, seen[k]])
	get_tree().quit()
