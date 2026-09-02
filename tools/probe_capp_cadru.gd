extends Node
## CE se vede in banda umarului exterior, la o fractie data.
##
## Reproduce camera din Snapshot --driver si trage raze prin coloanele din
## sfertul drept al cadrului, raportand ce ating: zid, horn, teren sau nimic
## (cer). Exista fiindca "peretele e la 62 m in dreapta" e o afirmatie despre
## LUME, iar reprosul e despre CADRU — iar intre ele sta directia in care se
## uita camera, care pe un viraj nu e perpendiculara pe `side`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappCadru.tscn -- --track=6 --frac=0.16

const MEASURE_DIST := 7.5
const MEASURE_HEIGHT := 2.6
const MEASURE_FOV := 60.0
const MEASURE_LOOK_AHEAD := 14.0
const MEASURE_LOOK_HEIGHT := 1.4


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	var frac := 0.16
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 4:
		await get_tree().process_frame

	var pts := track.baked
	var n := pts.size()
	var i0 := int(frac * float(n)) % n
	var focus: Vector3 = pts[i0]
	var ahead: Vector3 = pts[(i0 + 12) % n]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	var target := focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT

	# Baza camerei
	var fwd := (target - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var aspect := 1280.0 / 720.0
	var tan_v := tan(deg_to_rad(MEASURE_FOV) * 0.5)

	print("")
	print("=== ce se vede in cadru la frac %.3f ===" % frac)
	print("  ochi=(%.1f, %.2f, %.1f)  priveste catre (%.1f, %.2f, %.1f)" % [
		eye.x, eye.y, eye.z, target.x, target.y, target.z])
	var space := get_viewport().world_3d.direct_space_state
	# Coloane din sfertul drept (u de la 0.72 la 1.0), pe cateva inaltimi.
	var hits := {}
	var sky := 0
	var total := 0
	for cu in 24:
		var u := 0.72 + 0.28 * float(cu) / 23.0
		for cv in 14:
			# v de la 0.22 (sus) la 0.62 (spre linia orizontului)
			var v := 0.22 + 0.40 * float(cv) / 13.0
			var ndc_x := (u * 2.0 - 1.0) * tan_v * aspect
			var ndc_y := (1.0 - v * 2.0) * tan_v
			var rd := (fwd + right * ndc_x + up * ndc_y).normalized()
			var q := PhysicsRayQueryParameters3D.create(eye, eye + rd * 400.0)
			var hit := space.intersect_ray(q)
			total += 1
			if hit.is_empty():
				sky += 1
				continue
			var col := hit["collider"] as Node
			var nm := "?"
			while col != null:
				var s := String(col.name)
				if s.begins_with("zidValea"):
					nm = "ZID"; break
				if s.begins_with("horn") or s.begins_with("arcada") or s.begins_with("moloz"):
					nm = "horn"; break
				if s.begins_with("plop"):
					nm = "chiparos"; break
				if col.get_parent() == null:
					nm = "teren/altele"; break
				col = col.get_parent()
			hits[nm] = int(hits.get(nm, 0)) + 1
	print("  raze: %d" % total)
	print("    CER (nimic)      %4d  %.0f%%" % [sky, 100.0 * float(sky) / float(total)])
	for k: String in hits:
		print("    %-16s %4d  %.0f%%" % [k, hits[k], 100.0 * float(hits[k]) / float(total)])
	print("")
	get_tree().quit(0)
