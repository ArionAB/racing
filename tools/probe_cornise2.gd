extends Node
## Cornisele intra in cadrul de sofer? Proiectie directa a mesh-urilor lor.
const DIST := 7.5
const HEIGHT := 3.2
const FOV := 68.0
const LOOK_AHEAD := 14.0
const LOOK_HEIGHT := 1.2

func _ready() -> void:
	var ti := GameState.resolve_track_index(13)
	var track := (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate() as Track
	add_child(track)
	for i in range(8):
		await get_tree().process_frame
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(0.06 * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * DIST + Vector3.UP * HEIGHT
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = FOV
	cam.far = 400.0
	cam.global_position = eye
	cam.look_at(focus + dir * LOOK_AHEAD + Vector3.UP * LOOK_HEIGHT, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	var grp := track.find_child("FlanculErciyes", true, false)
	print("dala r0c3: x 768..1024  y 0..144   (ecran 1280x720)")
	var inside := 0
	for c in grp.get_children():
		var mi := (c as Node3D).find_children("*", "MeshInstance3D", true, false)
		if mi.is_empty():
			continue
		var m := mi[0] as MeshInstance3D
		var aabb := m.get_aabb()
		var xf := m.global_transform
		var mnx := 1e9; var mny := 1e9; var mxx := -1e9; var mxy := -1e9
		var behind := 0
		var dmin := 1e9
		for i in range(8):
			var p := xf * (aabb.position + aabb.size * Vector3(
				float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1)))
			if cam.is_position_behind(p):
				behind += 1
				continue
			var sp := cam.unproject_position(p)
			mnx = minf(mnx, sp.x); mxx = maxf(mxx, sp.x)
			mny = minf(mny, sp.y); mxy = maxf(mxy, sp.y)
			dmin = minf(dmin, eye.distance_to(p))
		if behind == 8:
			print("  %-20s TOT IN SPATE" % c.name)
			continue
		var ox := maxf(0.0, minf(mxx, 1024.0) - maxf(mnx, 768.0))
		var oy := maxf(0.0, minf(mxy, 144.0) - maxf(mny, 0.0))
		if ox > 0.0 and oy > 0.0:
			inside += 1
		print("  %-20s px x %7.0f..%7.0f  y %7.0f..%7.0f  dist %.0f m  in dala=%s  latime_px=%.0f inalt_px=%.0f" % [
			c.name, mnx, mxx, mny, mxy, dmin,
			"DA" if (ox > 0.0 and oy > 0.0) else "nu", mxx - mnx, mxy - mny])
	print("=> %d module cad in dala r0 c3" % inside)
	get_tree().quit()
