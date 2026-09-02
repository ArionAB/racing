extends Node
## Ce prop e in pixelul cerut din captura de la --driver? Fara asta, "palaria
## din dreapta" nu are nume, deci nu se poate cauta in .tscn.
##   godot --headless --path . res://tools/ProbeCappCine.tscn -- --frac=0.05 --px=890,140
const MD := 7.5
const MH := 3.2
const MF := 68.0
const MLA := 14.0
const MLH := 1.2
const W := 1280
const H := 720

func _ready() -> void:
	await get_tree().process_frame
	var frac := 0.05
	var pts_px: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			frac = float(a.split("=")[1])
		elif a.begins_with("--px="):
			var q: PackedStringArray = a.split("=")[1].split(",")
			pts_px.append(Vector2(float(q[0]), float(q[1])))
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 5:
		await get_tree().process_frame
	var cam := Camera3D.new()
	cam.fov = MF
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	get_viewport().size = Vector2i(W, H)
	await get_tree().process_frame
	var route: Object = t.route_at(0)
	var pts: PackedVector3Array = route.baked
	var n: int = pts.size()
	var idx: int = int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir: Vector3 = (ahead - focus).normalized()
	cam.global_position = focus - dir * MD + Vector3.UP * MH
	cam.look_at(focus + dir * MLA + Vector3.UP * MLH, Vector3.UP)
	await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	for sp in pts_px:
		var from := cam.project_ray_origin(sp)
		var rd := cam.project_ray_normal(sp)
		var q2 := PhysicsRayQueryParameters3D.create(from, from + rd * 300.0)
		var res := space.intersect_ray(q2)
		if res.is_empty():
			print("px %s -> nimic" % sp)
			continue
		var nd: Node = res["collider"]
		var chain := ""
		var a: Node = nd
		for i in 4:
			if a == null:
				break
			chain = String(a.name) + "/" + chain
			a = a.get_parent()
		print("px %s -> %s  la %.1f m" % [sp, chain, from.distance_to(res["position"])])
	get_tree().quit()
