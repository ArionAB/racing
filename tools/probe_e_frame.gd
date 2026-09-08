extends Node3D
## Unde cade lacul/crusta/flamingii in CADRUL erou, in coordonate de ecran.
## Raspunde la intrebarea criticului rundei 4 cu cifre de incadrare, nu de
## existenta: obiectele exista (ProbeMasca le numara), dar cad in coltul
## dreapta-jos in loc de banda mediana in care referinta are 11.7% crusta
## alba si 8.3% roz.
func _ready() -> void:
	var frac := 0.40
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			frac = float(a.trim_prefix("--frac="))
	var idx := GameState.resolve_track_index(7)
	var track: Track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	var cam := Camera3D.new()
	add_child(cam)
	var pts := track.route_at(0).baked
	var n := pts.size()
	var i := int(frac * float(n)) % n
	var focus: Vector3 = pts[i]
	var ahead: Vector3 = pts[track.route_at(0).wrap_index(i + 12)]
	var dir := (ahead - focus).normalized()
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 400.0
	cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	print("frac=%.3f  ochi=(%.1f,%.1f,%.1f)  focus=(%.1f,%.1f,%.1f)" % [frac,
		cam.position.x, cam.position.y, cam.position.z, focus.x, focus.y, focus.z])
	# --shift=dx,dz: unde AR cadea lacul daca poligonul s-ar muta. Raspunde
	# la intrebarea de incadrare fara sa editez inca scena.
	var shift := Vector3.ZERO
	for a2 in OS.get_cmdline_user_args():
		if a2.begins_with("--shift="):
			var sp2 := a2.trim_prefix("--shift=").split(",")
			shift = Vector3(float(sp2[0]), 0.0, float(sp2[1]))
	var zone := track.get_node_or_null("DecorManual/ZoneE_Buza")
	var poly := track._lagoon_poly()
	if not poly.is_empty():
		var cx := 0.0
		var cz := 0.0
		for p in poly:
			cx += p.x
			cz += p.y
		cx /= float(poly.size())
		cz /= float(poly.size())
		var sea: float = track._sea_level() if track.has_method("_sea_level") else 0.0
		_report(cam, vp, "centru lac", Vector3(cx, sea, cz) + shift)
		# muchia lacului dinspre drum si cea opusa
		var near_p := poly[0]
		var far_p := poly[0]
		for p in poly:
			if p.y < near_p.y:
				near_p = p
			if p.y > far_p.y:
				far_p = p
		_report(cam, vp, "mal apropiat", Vector3(near_p.x, sea, near_p.y) + shift)
		_report(cam, vp, "mal opus", Vector3(far_p.x, sea, far_p.y) + shift)
	if zone != null:
		for nm in ["E_Flamingi", "E_CrustaSare"]:
			var fl := zone.get_node_or_null(nm)
			if fl != null and fl is MultiMeshInstance3D:
				var ps: PackedVector3Array = fl.get("positions")
				var ymin := 9e9
				var ymax := -9e9
				var seen := 0
				for p in ps:
					var sp := cam.unproject_position(p)
					if cam.is_position_behind(p):
						continue
					seen += 1
					ymin = minf(ymin, sp.y / vp.y)
					ymax = maxf(ymax, sp.y / vp.y)
				print("%-14s %d instante in fata, banda y ecran %.2f .. %.2f" % [nm, seen, ymin, ymax])
	get_tree().quit()

func _report(cam: Camera3D, vp: Vector2, lbl: String, p: Vector3) -> void:
	if cam.is_position_behind(p):
		print("%-14s IN SPATELE camerei" % lbl)
		return
	var sp := cam.unproject_position(p)
	print("%-14s ecran x=%.2f y=%.2f  dist=%.1f m" % [lbl, sp.x / vp.x, sp.y / vp.y, cam.global_position.distance_to(p)])
