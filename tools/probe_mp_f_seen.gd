extends Node
## CE SE VEDE din albie, de la volan: pentru o grila de puncte din bazin, spune
## daca sunt (a) in frustumul camerei de joc si (b) NEOCLUZATE de teren.
##
## Rostul: runda 1 a pus raul in bazinul masurat si el n-a aparut in captura.
## „Langa drum" si „in cadru" sunt doua lucruri diferite (memoria
## `masoara-inainte-nu-langa`), iar „in cadru" si „nu e ascuns de o creasta"
## sunt inca doua. Sonda asta le separa, cu aceeasi camera ca Snapshot
## --gamecam.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpFSeen.tscn -- \
##       --frac=0.67 [--y=-34.2]

const TRACK := "res://scenes/tracks/Track15.tscn"
## Parametrii camerei de joc (scenes/race/chase_camera.gd).
const FOV := 68.0
const CAM_BACK := 12.5   # DEFAULT_DISTANCE
const CAM_UP := 10.0     # DEFAULT_HEIGHT — camera de joc e SUS
const LOOK_UP := 0.40    # LOOK_HEIGHT

var _track: Track
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _frac := 0.67
var _probe_y := -34.2


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			_frac = float(a.trim_prefix("--frac="))
		elif a.begins_with("--y="):
			_probe_y = float(a.trim_prefix("--y="))
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var n := _track.baked.size()
	var i := int(_frac * float(n)) % n
	var p := _track.baked[i]
	var i2 := (i + 6) % n
	var fwd := (_track.baked[i2] - p)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var cam := p - fwd * CAM_BACK + Vector3(0, CAM_UP, 0)
	var target := p + fwd * 12.0 + Vector3(0, LOOK_UP, 0)
	var view := (target - cam).normalized()
	var right := view.cross(Vector3.UP).normalized()
	var up := right.cross(view).normalized()
	var tan_v := tan(deg_to_rad(FOV * 0.5))
	var tan_h := tan_v * (1280.0 / 720.0)
	print("; camera (%.1f, %.1f, %.1f) priveste (%.2f, %.2f, %.2f); fov %.0f v / %.0f h grade"
		% [cam.x, cam.y, cam.z, view.x, view.y, view.z, FOV,
			2.0 * rad_to_deg(atan(tan_h))])
	print("; grila la y=%.1f: '#' = in cadru SI vizibil, '.' = in cadru dar ascuns de teren, ' ' = in afara cadrului" % _probe_y)
	print("; x de la -320 la -110 pas 10, z de la -240 la -120 pas 10")
	var space := _track.get_world_3d().direct_space_state
	var seen := 0
	var framed := 0
	var zz := -240.0
	while zz <= -120.0:
		var row := ""
		var xx := -320.0
		while xx <= -110.0:
			var q := Vector3(xx, _probe_y, zz)
			var v := q - cam
			var dz := v.dot(view)
			var ch := " "
			if dz > 1.0:
				var hx: float = absf(v.dot(right)) / dz
				var hy: float = absf(v.dot(up)) / dz
				if hx <= tan_h and hy <= tan_v:
					framed += 1
					ch = "."
					var rq := PhysicsRayQueryParameters3D.create(cam, q)
					rq.collide_with_areas = false
					var hit: Dictionary = space.intersect_ray(rq)
					if hit.is_empty():
						ch = "#"
						seen += 1
			row += ch
			xx += 10.0
		print("; z=%+7.1f |%s|" % [zz, row])
		zz += 10.0
	print("; TOTAL: %d celule in cadru, din care %d NEOCLUZATE" % [framed, seen])
	get_tree().quit(0)
