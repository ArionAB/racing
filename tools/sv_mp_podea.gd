extends Node
## Cat de jos e podeaua vaii sub drum, si CE e pe ea?
## Ipoteza: `_allowed` respinge orice prop cu is_ravine, deci podeaua ramane
## goala prin constructie. Sonda masoara, pe fiecare POI: adancimea podelei
## sub cota drumului la offseturi mari, si cate prop-uri exista acolo.
const TRACK := "res://scenes/tracks/Track15.tscn"
const POIS := {"A":[0.00,0.04], "B":[0.04,0.20], "C":[0.22,0.40], "D":[0.42,0.54],
	"E":[0.56,0.64], "F":[0.66,0.72], "G":[0.74,0.92], "H":[0.94,0.995]}
const OFFSETS := [20.0, 40.0, 70.0, 110.0]
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
	# Toate prop-urile din scena, ca pozitii.
	var props: Array[Vector3] = []
	_collect(_t, props)
	print("Prop-uri gasite in scena: %d" % props.size())
	print("")
	print("POI parte | adancimea podelei sub drum la offset lateral | prop-uri sub -8 m")
	print("          |   +20m    +40m    +70m   +110m               | (in fereastra)")
	for key: String in POIS:
		var rng: Array = POIS[key]
		for sgn: float in [1.0, -1.0]:
			var acc := [0.0, 0.0, 0.0, 0.0]
			var cnt := 0
			var deep := 0
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
				for k in OFFSETS.size():
					var p := bp + lat * ((w + float(OFFSETS[k])) * sgn)
					acc[k] += _sol(p.x, p.z) - bp.y
				cnt += 1
				f += 0.004
			if cnt == 0: continue
			for j in 4: acc[j] /= float(cnt)
			# prop-uri in felia asta, pe partea asta, mult sub drum
			for p in props:
				var res := _frac_side(p)
				if res.x < rng[0] or res.x >= rng[1]: continue
				if signf(res.y) != sgn: continue
				if res.z < -8.0: deep += 1
			print("%s   %s  | %+6.1f %+6.1f %+6.1f %+6.1f               | %d" % [
				key, ("dr" if sgn > 0.0 else "st"), acc[0], acc[1], acc[2], acc[3], deep])
	get_tree().quit(0)

## frac, side_sign, delta_y fata de drum
func _frac_side(p: Vector3) -> Vector3:
	var n := _t.baked.size()
	var best := 0
	var bd := INF
	for i in n:
		var q: Vector3 = _t.baked[i]
		var dd := (q.x - p.x) * (q.x - p.x) + (q.z - p.z) * (q.z - p.z)
		if dd < bd: bd = dd; best = i
	var bp: Vector3 = _t.baked[best]
	var nx: Vector3 = _t.baked[(best + 1) % n]
	var d := (nx - bp); d.y = 0.0
	if d.length() < 0.001: return Vector3(0.0, 1.0, 0.0)
	d = d.normalized()
	var lat := Vector3(-d.z, 0.0, d.x)
	var s := signf(lat.dot(p - bp))
	return Vector3(float(best) / float(n), s, p.y - bp.y)

func _collect(node: Node, out: Array[Vector3]) -> void:
	if node is MeshInstance3D or node is MultiMeshInstance3D:
		out.append((node as Node3D).global_position)
	for c in node.get_children():
		_collect(c, out)

func _sol(x: float, z: float) -> float:
	var sp := _t.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, -500.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	return float((r["position"] as Vector3).y) if not r.is_empty() else -999.0
