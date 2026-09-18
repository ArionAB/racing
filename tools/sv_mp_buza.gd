extends Node
## Cat de aproape de CAROSABIL incepe caderea, pe fiecare POI.
## Criticii valului 2 au cerut, toti trei si in toate rundele, acelasi lucru:
## "nu exista buza / muchie / cadere langa drum". Sonda asta pune cifra pe el.
## Masoara, pe fiecare felie de POI: unde se termina asfaltul (semi-latimea) si
## cat de departe lateral trebuie sa mergi ca sa cazi 3 m, 10 m si 25 m.
const TRACK := "res://scenes/tracks/Track15.tscn"
const POIS := {
	"A 0.00-0.04": [0.00, 0.04], "B 0.04-0.20": [0.05, 0.20],
	"C 0.22-0.40": [0.22, 0.40], "D 0.42-0.54": [0.42, 0.54],
	"E 0.56-0.64": [0.56, 0.64], "F 0.66-0.72": [0.66, 0.72],
	"G 0.74-0.92": [0.74, 0.92], "H 0.94-1.00": [0.94, 0.995],
}
var _track: Track
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus = hi + 200.0
	var n := _track.baked.size()
	print("=== DISTANTA DE LA MARGINEA DRUMULUI PANA LA CADERE ===")
	print("Pe fiecare parte: cati metri lateral DINCOLO de asfalt pana cazi 3/10/25 m.")
	print("'-' = nu se atinge nici la 60 m dincolo de margine (adica: nu exista cadere).")
	print("")
	print("POI                parte   semi_lat   -3m    -10m   -25m")
	for key: String in POIS:
		var rng: Array = POIS[key]
		for sgn: float in [1.0, -1.0]:
			var d3 := 0.0
			var d10 := 0.0
			var d25 := 0.0
			var cnt := 0
			var wsum := 0.0
			var f: float = rng[0]
			while f < rng[1]:
				var idx := int(round(f * float(n))) % n
				var bp: Vector3 = _track.baked[idx]
				var nx: Vector3 = _track.baked[(idx + 1) % n]
				var dir := (nx - bp); dir.y = 0.0
				if dir.length() < 0.001: f += 0.004; continue
				dir = dir.normalized()
				var lat := Vector3(-dir.z, 0.0, dir.x)
				var w := _track.width_at_index(idx)
				wsum += w
				var h3 := -1.0
				var h10 := -1.0
				var h25 := -1.0
				var extra := 0.5
				while extra <= 60.0:
					var p := bp + lat * ((w + extra) * sgn)
					var drop := bp.y - _sol(p.x, p.z)
					if h3 < 0.0 and drop >= 3.0: h3 = extra
					if h10 < 0.0 and drop >= 10.0: h10 = extra
					if h25 < 0.0 and drop >= 25.0: h25 = extra
					extra += 0.5
				d3 += (h3 if h3 > 0.0 else 99.0)
				d10 += (h10 if h10 > 0.0 else 99.0)
				d25 += (h25 if h25 > 0.0 else 99.0)
				cnt += 1
				f += 0.004
			if cnt == 0: continue
			print("%-18s %s     %5.2f   %s  %s  %s" % [
				key, ("dr" if sgn > 0.0 else "st"), wsum / float(cnt),
				_fmt(d3 / float(cnt)), _fmt(d10 / float(cnt)), _fmt(d25 / float(cnt))])
	get_tree().quit(0)

func _fmt(v: float) -> String:
	return "   -  " if v > 90.0 else "%5.1f " % v

func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	return float((r["position"] as Vector3).y) if not r.is_empty() else -999.0
