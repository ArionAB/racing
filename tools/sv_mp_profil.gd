extends Node
## Profilul lateral COMPLET pe POI-urile candidate: cota solului din 5 in 5 m
## pana la 140 m, ca sa se vada daca e vale (fund larg) sau sant (cade si urca).
const TRACK := "res://scenes/tracks/Track15.tscn"
const POIS := {"B":[0.04,0.20], "C":[0.22,0.40], "E":[0.56,0.64], "G":[0.74,0.92], "H":[0.94,0.995]}
var _t: Track
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	for i in 4: await get_tree().process_frame
	var hi := -INF
	for bp in _t.baked: hi = maxf(hi, bp.y)
	_sus = hi + 300.0
	print("Cota solului fata de drum, din 10 in 10 m lateral (medie pe POI)")
	print("POI pt |   10    20    30    40    50    60    70    80    90   100   120   140")
	var offs := [10.0,20.0,30.0,40.0,50.0,60.0,70.0,80.0,90.0,100.0,120.0,140.0]
	for key: String in POIS:
		var rng: Array = POIS[key]
		for sgn: float in [1.0, -1.0]:
			var acc := []
			for i in offs.size(): acc.append(0.0)
			var cnt := 0
			var f: float = rng[0]
			while f < rng[1]:
				var n := _t.baked.size()
				var i := int(round(f * float(n))) % n
				var bp: Vector3 = _t.baked[i]
				var nx: Vector3 = _t.baked[(i + 1) % n]
				var d := (nx - bp); d.y = 0.0
				if d.length() < 0.001: f += 0.004; continue
				d = d.normalized()
				var lat := Vector3(-d.z, 0.0, d.x)
				var w := _t.width_at_index(i)
				for k in offs.size():
					var p := bp + lat * ((w + float(offs[k])) * sgn)
					acc[k] += _sol(p.x, p.z) - bp.y
				cnt += 1
				f += 0.004
			if cnt == 0: continue
			var line := "%s  %s |" % [key, ("dr" if sgn > 0.0 else "st")]
			for j in offs.size():
				line += " %5.1f" % (acc[j] / float(cnt))
			print(line)
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	var sp := _t.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, -500.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	return float((r["position"] as Vector3).y) if not r.is_empty() else -999.0
