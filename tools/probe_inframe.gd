extends Node
## CE anume e in coltul din dreapta-jos al cadrului la o fractie data.
##
## ProbePile spune 0 suprapuneri, dar in imagine coltul e un sir de panze lipite
## una de alta. Cand sonda si imaginea nu sunt de acord, imaginea are dreptate —
## deci intreb cadrul, nu lista: proiectez fiecare panza in coordonate de ecran
## si tiparesc ce cade in coltul de jos-dreapta.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRAC: float = 0.245


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	# EXACT camera din snapshot.gd --driver (MEASURE_*), altfel sonda descrie
	# alt cadru decat cel judecat: prima versiune punea baloanele in STANGA
	# fiindca privea pe tangenta, nu cu 12 puncte inainte ca Snapshot.
	var i := int(FRAC * float(n)) % n
	var p := s.baked_point(i)
	var ahead := s.baked_point((i + 12) % n)
	var dir := (ahead - p).normalized()
	var eye := p - dir * 7.5 + Vector3.UP * 3.2
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 68.0
	cam.far = 400.0
	cam.look_at_from_position(eye, p + dir * 14.0 + Vector3.UP * 1.2, Vector3.UP)
	await get_tree().process_frame
	var items: Array = []
	_walk(t, items)
	print("=== panze proiectate in cadru (frac %.3f) ===" % FRAC)
	var vp := get_viewport().get_visible_rect().size
	for it in items:
		var nm: String = it[0]
		var pos: Vector3 = it[1]
		if cam.is_position_behind(pos):
			continue
		var sp := cam.unproject_position(pos)
		var u := sp.x / vp.x
		var v := sp.y / vp.y
		if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
			continue
		var d := eye.distance_to(pos)
		if not (u > 0.60 and v > 0.45):
			continue
		print("  %-34s ecran(%.2f, %.2f) dist %5.1f m" % [nm, u, v, d])
	get_tree().quit()


func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		var nm := String(c.name)
		# ORICE Node3D vizibil, nu doar panzele: coltul din dreapta-jos s-a
		# dovedit ca NU e panze (toate ies in stanga cadrului), deci intreb
		# cadrul ce e acolo in loc sa presupun.
		if c is Node3D and not nm.ends_with("_col") and (c as Node3D).visible:
			out.append([nm, (c as Node3D).global_position])
		_walk(c, out)
