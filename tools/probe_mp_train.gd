extends Node
## Trenul de pe malul raului (Machu Picchu F, issue #601): unde e, se vede, ce
## taie. Masoara, nu presupune.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpTrain.tscn
##
##   1. POZITIE: nodul, sina, capetele ei in lume.
##   2. VIZIBILITATE: pentru pozitii ale garniturii de-a lungul sinei, cate
##      camere de joc (frac 0.55-0.85) o vad (frustum + raza neocluzata).
##   3. CULOAR: corpuri de coliziune (decor, stanci, teren) in gabaritul trenului
##      pe toata sina, si noduri de DecorManual la mai putin de 5 m de axa sinei.
const FOV := 68.0
const CAM_BACK := 12.5
const CAM_UP := 10.0
const LOOK_UP := 0.40


func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track15.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for _i in 10:
		await get_tree().physics_frame
	if "--no-gallery" in OS.get_cmdline_user_args():
		for g in t.find_children("Galerie*", "BusDepot", true, false):
			g.queue_free()
		for _i in 3:
			await get_tree().physics_frame
	var trains := t.find_children("*", "TrainHazard", true, false)
	print("trenuri: %d" % trains.size())
	if trains.is_empty():
		get_tree().quit(0)
		return
	var tr := trains[0] as TrainHazard
	var gx := tr.global_transform
	print("tren: %s la %s, rot_y=%.1f grade, half_rail=%.0f, period=%.0f" % [
		tr.name, str(tr.global_position), rad_to_deg(tr.rotation.y), tr.half_rail, tr.period])
	var tb: Node3D = tr.get("_train")
	var mn := Vector3(INF, INF, INF)
	var mx := -mn
	for mi in tb.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var bb := tb.global_transform.affine_inverse() * m.global_transform * m.get_aabb()
		mn = mn.min(bb.position)
		mx = mx.max(bb.end)
	print("gabarit garnitura (local trenului): x %.1f..%.1f  y %.2f..%.2f  z %.2f..%.2f (latime %.2f, inaltime %.2f)" % [
		mn.x, mx.x, mn.y, mx.y, mn.z, mx.z, mx.z - mn.z, mx.y - mn.y])
	var a := gx * Vector3(-tr.half_rail, 0, 0)
	var b := gx * Vector3(tr.half_rail, 0, 0)
	print("sina: (%.0f,%.0f,%.0f) -> (%.0f,%.0f,%.0f)" % [a.x, a.y, a.z, b.x, b.y, b.z])
	var n := t.baked.size()
	var cams: Array = []
	var i := int(0.55 * n)
	while i < int(0.85 * n):
		var p := t.baked[i]
		var fwd := t.baked[(i + 6) % n] - p
		fwd.y = 0.0
		fwd = fwd.normalized()
		var cam := p - fwd * CAM_BACK + Vector3(0, CAM_UP, 0)
		var view := ((p + fwd * 12.0 + Vector3(0, LOOK_UP, 0)) - cam).normalized()
		var right := view.cross(Vector3.UP).normalized()
		cams.append([cam, view, right, right.cross(view).normalized(), float(i) / n])
		i += 4
	var space := t.get_world_3d().direct_space_state
	var tv := tan(deg_to_rad(FOV * 0.5))
	var th := tv * 16.0 / 9.0
	var trid: RID = RID()
	var x := -tr.half_rail
	var tot_seen := 0
	while x <= tr.half_rail:
		var q := gx * Vector3(x, 2.2, 0)
		var seen := 0
		var fmin := 9.0
		var fmax := -1.0
		var dmin := 1e9
		for cm in cams:
			var v: Vector3 = q - cm[0]
			var dz: float = v.dot(cm[1])
			if dz < 1.0:
				continue
			if absf(v.dot(cm[2])) / dz > th or absf(v.dot(cm[3])) / dz > tv:
				continue
			var rq := PhysicsRayQueryParameters3D.create(cm[0], q)
			rq.collide_with_areas = false
			if space.intersect_ray(rq).is_empty():
				seen += 1
				fmin = minf(fmin, cm[4])
				fmax = maxf(fmax, cm[4])
				dmin = minf(dmin, v.length())
		tot_seen += seen
		print("  x=%+5.0f  (%.0f,%.0f,%.0f)  vazut de %d camere %s  dist_min=%s" % [x, q.x, q.y, q.z, seen,
			("frac %.3f..%.3f" % [fmin, fmax]) if seen > 0 else "-", ("%.0f m" % dmin) if seen > 0 else "-"])
		x += 10.0
	print("TOTAL pozitii-camera care vad trenul: %d" % tot_seen)
	# CAPETELE: la aparitie (k=0) si la disparitie (k=1) NICIUN punct al garniturii
	# nu e vazut de vreo camera (trenul teleportat sub lume = pop). Formula de pozitie
	# e cea din TrainHazard._physics_process: x = -half_rail - len + (2*half_rail + len) * k.
	var tlen: float = tr.get("_train_len")
	var ends_ok := true
	for end_k: float in [0.0, 1.0]:
		var px := -tr.half_rail - tlen + (tr.half_rail * 2.0 + tlen) * end_k
		var seen_end := 0
		var worst := ""
		for cm in cams:
			var hit := false
			var dx := 0.0
			while dx <= tlen and not hit:
				for hh: float in [0.4, 4.2]:
					for lat: float in [-1.5, 1.5]:
						var q := gx * Vector3(px + dx, hh, lat)
						var v: Vector3 = q - cm[0]
						var dz: float = v.dot(cm[1])
						if dz < 1.0:
							continue
						if absf(v.dot(cm[2])) / dz > th or absf(v.dot(cm[3])) / dz > tv:
							continue
						var rq := PhysicsRayQueryParameters3D.create(cm[0], q)
						rq.collide_with_areas = false
						if space.intersect_ray(rq).is_empty():
							hit = true
							break
					if hit:
						break
				dx += 5.0
			if hit:
				seen_end += 1
		var okk := seen_end == 0
		ends_ok = ends_ok and okk
		print("%s %s: garnitura intre x=%.1f si x=%.1f (local), vazuta de %d camere" % [
			"PASS" if okk else "FAIL", "APARITIE" if end_k == 0.0 else "DISPARITIE", px, px + tlen, seen_end])
	# CULOARUL: gabaritul garniturii (3.6 m lat, de la 0.7 la 4.2 m deasupra sinei; garnitura are 2.9 x 3.9, rotile si talpa raman sub 0.7) pe
	# toata sina intre galerii, in cutii de 6 m: nimic de coliziune (decor, stanca,
	# teren) si niciun nod de DecorManual la mai putin de 6 m de axa.
	var corridor_ok := true
	var names := {}
	x = -35.0
	while x <= 60.0:
		var shape := BoxShape3D.new()
		shape.size = Vector3(6.0, 3.5, 3.6)
		var qp := PhysicsShapeQueryParameters3D.new()
		qp.shape = shape
		qp.transform = gx * Transform3D(Basis.IDENTITY, Vector3(x, 0.7 + 1.75, 0))
		for hh in space.intersect_shape(qp, 32):
			var col := hh["collider"] as Node
			var nm := str(col.name) if col != null else "?"
			if not names.has(nm):
				names[nm] = x
			else:
				names[nm] = str(names[nm]) + "," + str(x)
		x += 6.0
	if not names.is_empty():
		corridor_ok = false
	print("%s CULOAR: corpuri in gabaritul trenului (nume: primul x): %s" % [
		"PASS" if names.is_empty() else "FAIL", str(names)])
	var near := []
	for c in t.find_children("*", "Node3D", true, false):
		var n3 := c as Node3D
		if n3.get_parent() == null or not str(n3.get_parent().name).begins_with("Zone"):
			continue
		var lp := gx.affine_inverse() * n3.global_position
		if absf(lp.z) < 6.0 and lp.x > -38.0 and lp.x < tr.half_rail - 1.5:
			near.append("%s(x=%.0f,z=%.1f,y=%.1f)" % [n3.name, lp.x, lp.z, lp.y])
	if not near.is_empty():
		corridor_ok = false
	print("%s CULOAR: noduri DecorManual la < 6 m de axa: %d %s" % [
		"PASS" if near.is_empty() else "FAIL", near.size(), str(near)])
	ends_ok = ends_ok and corridor_ok
	print("
%s" % ("PASS" if ends_ok else "FAIL"))
	get_tree().quit(0 if ends_ok else 1)
