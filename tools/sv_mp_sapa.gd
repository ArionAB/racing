extends Node
## De ce nu exista buza langa asfalt, desi TOATE rapele au flag de cornisa?
## Ipoteza: sapatura e `min(teren, tinta)` — rapa SAPA, nu ridica. Unde terenul
## natural e deja SUB cota drumului, tinta cade deasupra solului si nu se taie
## nimic: panta lina supravietuieste. Sonda compara, chiar langa margine:
##   cota drumului  vs  cota solului la +1 m dincolo de asfalt
## Daca solul e deja sub drum, nu exista muchie de taiat.
const TRACK := "res://scenes/tracks/Track15.tscn"
const POIS := {"C":[0.22,0.40], "D":[0.42,0.54], "H":[0.94,0.995], "G":[0.74,0.92]}
var _t: Track
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _t.baked: hi = maxf(hi, bp.y)
	_sus = hi + 200.0
	var n := _t.baked.size()
	print("POI parte |  y_drum  y_la+1m  y_la+4m  y_la+10m | delta la +1m (negativ = solul e DEJA sub drum)")
	for key: String in POIS:
		var rng: Array = POIS[key]
		for sgn: float in [1.0, -1.0]:
			var a := [0.0, 0.0, 0.0, 0.0]
			var cnt := 0
			var f: float = rng[0]
			while f < rng[1]:
				var i := int(round(f * float(n))) % n
				var bp: Vector3 = _t.baked[i]
				var nx: Vector3 = _t.baked[(i + 1) % n]
				var d := (nx - bp); d.y = 0.0
				if d.length() < 0.001: f += 0.005; continue
				d = d.normalized()
				var lat := Vector3(-d.z, 0.0, d.x)
				var w := _t.width_at_index(i)
				a[0] += bp.y
				var k := 1
				for off: float in [1.0, 4.0, 10.0]:
					var p := bp + lat * ((w + off) * sgn)
					a[k] += _sol(p.x, p.z)
					k += 1
				cnt += 1
				f += 0.005
			if cnt == 0: continue
			for j in 4: a[j] /= float(cnt)
			print("%s   %s  | %+7.1f %+7.1f %+7.1f %+8.1f | %+6.1f m%s" % [
				key, ("dr" if sgn > 0.0 else "st"), a[0], a[1], a[2], a[3], a[1] - a[0],
				("   <- nimic de sapat" if a[1] - a[0] < -0.5 else "")])
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	var sp := _t.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	return float((r["position"] as Vector3).y) if not r.is_empty() else -999.0
