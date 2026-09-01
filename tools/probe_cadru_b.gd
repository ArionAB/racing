extends Node
## Unde priveste cadrul de sofer la frac 0.06, in metri de lume.
##
## Fara asta, "pune forme in banda de jos" e o ghicitoare: banda masurata
## (y 0.55-1.0, x 0.20-0.80) e o FEREASTRA DE ECRAN, iar ce cade in ea depinde
## de pozitia camerei, nu de fractie. Sonda proiecteaza inapoi: pentru colturile
## ferestrei, unde intersecteaza raza planul solului.
const MEASURE_DIST := 7.5
const MEASURE_HEIGHT := 3.2
const MEASURE_FOV := 68.0
const MEASURE_LOOK_AHEAD := 14.0
const MEASURE_LOOK_HEIGHT := 1.2

func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var idx := int(0.06 * float(n)) % n
	var focus: Vector3 = r.baked[idx]
	var ahead: Vector3 = r.baked[(idx + 12) % n]
	var dir := (ahead - focus).normalized()
	var right := dir.cross(Vector3.UP).normalized()
	var eye := focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	var tgt := focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT
	print("focus  = (%.2f, %.2f, %.2f)" % [focus.x, focus.y, focus.z])
	print("eye    = (%.2f, %.2f, %.2f)" % [eye.x, eye.y, eye.z])
	print("target = (%.2f, %.2f, %.2f)" % [tgt.x, tgt.y, tgt.z])
	print("dir    = (%.3f, %.3f, %.3f)  right = (%.3f, %.3f, %.3f)" % [dir.x, dir.y, dir.z, right.x, right.y, right.z])
	# camera reala, ca sa proiectez exact ca snapshot.gd
	var cam := Camera3D.new()
	get_tree().root.add_child(cam)
	cam.fov = MEASURE_FOV
	cam.far = 400.0
	cam.position = eye
	cam.look_at(tgt, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	var vp := Vector2(1280, 720)
	print("")
	print("--- colturile ferestrei masurate, proiectate pe planul solului ---")
	for uv in [Vector2(0.20, 0.55), Vector2(0.80, 0.55), Vector2(0.20, 1.0),
			Vector2(0.80, 1.0), Vector2(0.50, 0.55), Vector2(0.50, 0.78)]:
		var sp := Vector2(uv.x * vp.x, uv.y * vp.y)
		var o := cam.project_ray_origin(sp)
		var d := cam.project_ray_normal(sp)
		# intersectie cu planul orizontal la cota focusului
		if absf(d.y) < 0.0001:
			continue
		var tt := (focus.y - o.y) / d.y
		if tt < 0.0:
			print("  uv %.2f,%.2f -> deasupra orizontului" % [uv.x, uv.y])
			continue
		var w: Vector3 = o + d * tt
		var rel := w - focus
		print("  uv %.2f,%.2f -> lume (%.1f, %.1f, %.1f)  inainte %.1f m  lateral %.1f m" % [
			uv.x, uv.y, w.x, w.y, w.z, rel.dot(dir), rel.dot(right)])
	# si invers: unde cade pe ecran un punct la X m inainte, Y m lateral
	print("")
	print("--- unde cad pe ECRAN puncte de la sol (u, v normalizate) ---")
	for fwd in [5.0, 10.0, 15.0, 20.0, 25.0, 35.0]:
		var line := "  inainte %5.1f m:" % fwd
		for lat in [-14.0, -9.0, -7.0, 7.0, 9.0, 14.0]:
			var w: Vector3 = focus + dir * fwd + right * lat
			var sp := cam.unproject_position(w)
			line += "  lat%+5.1f(%.2f,%.2f)" % [lat, sp.x / vp.x, sp.y / vp.y]
		print(line)
	print("")
	print("--- inaltimea pe ecran a unei forme de H m, la X m inainte, lat L ---")
	for fwd in [8.0, 12.0, 18.0, 25.0]:
		for lat in [8.0, 11.0]:
			for hh in [2.0, 4.0, 6.0]:
				var b: Vector3 = focus + dir * fwd + right * lat
				var sb := cam.unproject_position(b)
				var st := cam.unproject_position(b + Vector3.UP * hh)
				print("  fwd %4.1f lat %4.1f H %3.1f -> baza v=%.2f  varf v=%.2f  u=%.2f" % [
					fwd, lat, hh, sb.y / vp.y, st.y / vp.y, sb.x / vp.x])
	get_tree().quit(0)
