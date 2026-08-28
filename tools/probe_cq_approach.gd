extends Node
## Trece gabaritul masinii prin POI F? Plimbam o cutie de dimensiunea masinii
## pe AXA TRASEULUI (nu pe axa modulului) si raportam podeaua de sub ea si
## orice zid din fata. Asta e testul care conteaza, nu razele in spatiul
## modulului: dincolo de placa ele lovesc terenul din alt punct.
const CAR := Vector3(1.9, 1.1, 4.0)
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	var shape := BoxShape3D.new()
	shape.size = CAR
	var prev_y := INF
	var worst_step := 0.0
	var holes := 0
	var blocks := 0
	print("frac  | lat | podea  | pas   | stare")
	var f := 0.640
	while f <= 0.665:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		for lat: float in [-4.0, 0.0, 4.0]:
			var p := c + side * lat
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 6.0, p + Vector3.DOWN * 10.0)
			var h := space.intersect_ray(q)
			if h.is_empty():
				holes += 1
				print("%.4f | %+4.1f |   ---- |       | GOL" % [f, lat])
				continue
			var y: float = h.position.y
			# zid in fata: cutia masinii, ridicata pe podea
			var par := PhysicsShapeQueryParameters3D.new()
			par.shape = shape
			par.transform = Transform3D(Basis(Vector3.UP, atan2(fw.x, fw.z)), p + Vector3.UP * (CAR.y * 0.5 + 0.25))
			var hits := space.intersect_shape(par, 8)
			var solid := 0
			for hh in hits:
				var col = hh.collider
				if col == null:
					continue
				var nm := str(col.name)
				if nm == "Gate":
					continue
				# podeaua e normala; ne intereseaza ce sta VERTICAL in fata
				solid += 1
			var step := 0.0
			if is_finite(prev_y) and lat == 0.0:
				step = absf(y - prev_y)
				worst_step = maxf(worst_step, step)
			if lat == 0.0:
				prev_y = y
			var flag := ""
			# distanta reala intre esantioane, ca sa iasa PANTA
			var dstep := r.baked[i].distance_to(r.baked[(i - 1 + n) % n])
			if step > 0.35 and dstep > 0.05 and step / dstep > 0.6:
				flag = "PRAG %.2f pe %.2f m (%.0f%%)" % [step, dstep, step / dstep * 100.0]
			if flag != "":
				print("%.4f | %+4.1f | %6.2f | %5.2f | %s" % [f, lat, y, step, flag])
		f += 0.0002
	print("--- goluri: %d | cel mai mare pas pe axa: %.2f m" % [holes, worst_step])
	get_tree().quit()
