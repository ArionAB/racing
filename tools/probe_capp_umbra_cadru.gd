extends Node
## Ajunge umbra hornului PE BANDA, in cadru? Nu "exista casteri", ci: pentru
## fiecare horn, unde cade varful umbrei lui, si e acolo drum?
##
## Runda 5, dupa ce mutarea azimutului a imbunatatit cifra si a inrautatit poza.
## Sonda care numara casteri trece si cu ecranul gol (MEMORY: efecte invizibile
## nu se numara), deci asta nu numara nimic — proiecteaza.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappUmbraCadru.tscn -- --track=6


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sun: DirectionalLight3D = null
	var stack: Array[Node] = [track]
	var casters: Array = []
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is DirectionalLight3D:
			sun = n as DirectionalLight3D
		if n is GeometryInstance3D:
			var gi := n as GeometryInstance3D
			if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and gi.visible:
				var aabb := gi.get_aabb()
				casters.append({"n": gi.name, "p": gi.global_position,
					"h": aabb.size.y * gi.global_transform.basis.get_scale().y})

	var dir := -sun.global_transform.basis.z
	var sh := Vector2(dir.x, dir.z).normalized()
	var elev: float = absf(sun.global_rotation_degrees.x)
	var cascade: float = sun.directional_shadow_max_distance
	print("")
	print("=== umbra pe banda, la frac 0.10 ===")
	print("  elevatie %.1f  cascada %.1f m  umbra spre (%.2f, %.2f)" % [elev, cascade, sh.x, sh.y])

	var pts: PackedVector3Array = track.baked
	var n_pts := pts.size()
	var i0 := int(0.10 * float(n_pts)) % n_pts
	var car: Vector3 = pts[i0]
	var ahead: Vector3 = pts[(i0 + 12) % n_pts]
	var fwd := (ahead - car); fwd.y = 0.0; fwd = fwd.normalized()
	# camera de urmarire: 12.5 m in spate, priveste inainte
	var cam := car - fwd * 12.5
	print("  masina %s  fwd (%.2f, %.2f)" % [str(car.round()), fwd.x, fwd.z])

	# Pentru fiecare caster din apropiere: lungimea umbrei si unde cade varful.
	var tan_e: float = tan(deg_to_rad(elev))
	if true:
		print("")
		print("=== baleiaj elevatie x azimut: cate umbre cad PE banda ===")
		print("  (varf de umbra la mai putin de 8 m de axa benzii)")
		print("  elev\y   0    10    20    25    30    40    50")
		for ev in [13, 16, 19, 22, 25, 28, 32, 36, 40]:
			var line := "  %4d " % ev
			for yy in [0, 10, 20, 25, 30, 40, 50]:
				var bb := Basis.from_euler(Vector3(deg_to_rad(-float(ev)), deg_to_rad(float(yy)), 0.0))
				var dd2 := -bb.z
				var sh2 := Vector2(dd2.x, dd2.z).normalized()
				var te: float = tan(deg_to_rad(float(ev)))
				var cnt := 0
				for c in casters:
					var pp: Vector3 = c["p"]
					var dcam: float = Vector2(pp.x - cam.x, pp.z - cam.z).length()
					if dcam > 90.0: continue
					var hh: float = c["h"]
					if hh < 3.0: continue
					var tp := Vector2(pp.x, pp.z) + sh2 * (hh / maxf(0.05, te))
					var bst := 1e9
					for k in range(0, n_pts, 3):
						var qq: Vector3 = pts[k]
						var d3: float = Vector2(qq.x - tp.x, qq.z - tp.y).length()
						if d3 < bst: bst = d3
					if bst < 8.0: cnt += 1
				line += "%5d " % cnt
			print(line)
	var in_lane := 0
	var in_box := 0
	var out_box := 0
	var rows: Array = []
	for c in casters:
		var p: Vector3 = c["p"]
		var d_cam: float = Vector2(p.x - cam.x, p.z - cam.z).length()
		if d_cam > 120.0:
			continue
		var h: float = c["h"]
		if h < 3.0:
			continue
		var slen: float = h / maxf(0.05, tan_e)
		var tip := Vector2(p.x, p.z) + sh * slen
		# distanta de la varful umbrei la axa benzii (cel mai apropiat punct baked)
		var best := 1e9
		for k in range(n_pts):
			var q: Vector3 = pts[k]
			var dd: float = Vector2(q.x - tip.x, q.z - tip.y).length()
			if dd < best:
				best = dd
		# e casterul in caseta cascadei? (aproximativ: distanta fata de camera)
		var inside: bool = d_cam <= cascade
		if inside: in_box += 1
		else: out_box += 1
		var hits: bool = best < 8.0
		if hits and inside: in_lane += 1
		rows.append({"n": c["n"], "d": d_cam, "h": h, "slen": slen,
			"miss": best, "in": inside, "hit": hits})
	rows.sort_custom(func(a, b): return a["d"] < b["d"])
	print("")
	print("  caster              d_cam   h     umbra   varf_la_banda  in_cascada")
	for r in rows.slice(0, 22):
		print("  %-18s %6.1f %5.1f %7.1f %10.1f      %s" % [
			str(r["n"]).substr(0, 18), r["d"], r["h"], r["slen"], r["miss"],
			"DA" if r["in"] else "NU"])
	print("")
	print("  casteri sub 120 m: %d   in cascada: %d   afara: %d" % [rows.size(), in_box, out_box])
	print("  cu varful umbrei pe banda SI in cascada: %d" % in_lane)
	get_tree().quit(0)
