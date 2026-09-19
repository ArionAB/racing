extends Node
## Survey pentru VERDICTUL RUNDEI 3 pe POI B: "drumul nu e taiat in nimic, e un
## terasament cu umar de iarba pe ambele parti, iar stanca sta la 20+ m in stanga,
## separata de asfalt".
##
## Masoara EXACT cele doua cifre din verdict, pe fiecare frac de captura:
##   STANGA: cati metri dincolo de marginea asfaltului pana cand solul URCA
##           peste cota drumului cu 1 / 3 / 8 m  -> "umarul de iarba"
##   DREAPTA: cati metri dincolo de margine pana cand solul COBOARA sub drum
##           cu 1 / 3 / 10 m                     -> "caderea incepe de la pavaj?"
## Plus unghiul din ochiul soferului (camera la 6 m peste ax) catre primul punct
## de perete: un perete la 20 m nu e "taiat in stanca", unul la 1,5 m e.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus_y := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus_y = hi + 250.0
	var n := _track.baked.size()

	print("=== POI B — UMARUL, masurat de la MARGINEA asfaltului ===")
	print("stanga = latura peretelui (urca); dreapta = latura defileului (coboara)")
	print("")
	print("frac   semi  | STANGA: m dincolo de margine pana la +1m/+3m/+8m")
	print("             | DREAPTA: m dincolo de margine pana la -1m/-3m/-10m")
	for f in range(40, 211, 10):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var nx: Vector3 = _track.baked[(idx + 1) % n]
		var dir := (nx - bp); dir.y = 0.0
		if dir.length() < 0.001: continue
		dir = dir.normalized()
		var lat := Vector3(-dir.z, 0.0, dir.x)
		var w := _track.width_at_index(idx)
		var st := _scan(bp, lat, -1.0, w, [1.0, 3.0, 8.0], 1.0)
		var dr := _scan(bp, lat, 1.0, w, [-1.0, -3.0, -10.0], -1.0)
		print("%.3f  %4.2f | ST %s | DR %s" % [frac, w, st, dr])

	print("")
	print("=== Profilul lateral brut (cota fata de ax), de la MARGINE in afara ===")
	print("frac   parte |  +0    +1    +2    +3    +5    +8   +12   +16   +20   +25")
	for f in [40, 80, 100, 140, 180, 200]:
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var nx: Vector3 = _track.baked[(idx + 1) % n]
		var dir := (nx - bp); dir.y = 0.0
		if dir.length() < 0.001: continue
		dir = dir.normalized()
		var lat := Vector3(-dir.z, 0.0, dir.x)
		var w := _track.width_at_index(idx)
		for sgn: float in [-1.0, 1.0]:
			var row := "%.3f   %s  |" % [frac, ("st" if sgn < 0.0 else "dr")]
			for extra: float in [0.0, 1.0, 2.0, 3.0, 5.0, 8.0, 12.0, 16.0, 20.0, 25.0]:
				var p := bp + lat * ((w + extra) * sgn)
				var y := _sol(p.x, p.z)
				row += ("  ----" if y < -900.0 else " %+5.1f" % [y - bp.y])
			print(row)
	get_tree().quit(0)

func _scan(bp: Vector3, lat: Vector3, sgn: float, w: float, targets: Array, dirn: float) -> String:
	var out := ""
	for t: float in targets:
		var hit := -1.0
		var d := 0.0
		while d <= 40.0:
			var p := bp + lat * ((w + d) * sgn)
			var y := _sol(p.x, p.z)
			if y > -900.0 and (y - bp.y) * dirn >= absf(t):
				hit = d; break
			d += 0.25
		out += ("   --" if hit < 0.0 else " %5.2f" % [hit])
	return out

func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus_y, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	if r.is_empty(): return -999.0
	return float((r["position"] as Vector3).y)
