extends Node
## UNDE, in lume, se uita camera de joc — ca sa se stie unde trebuie sa fie
## stanca, in loc sa fie mutata prin incercari.
##
## Se trag raze pe o grila prin frustum si se raporteaza, pentru cele care ating
## solul, rulajul lateral fata de AXUL benzii (pozitiv = spre vale) si distanta
## pe traseu. Asa se vede in ce fasie de teren cade masa de pixeli din dreapta
## cadrului — acolo si numai acolo poate faleza sa devina vizibila.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var space := get_viewport().world_3d.direct_space_state
	for f: float in [0.22, 0.28, 0.34]:
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		var eye := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var target := focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
		var fwd := (target - eye).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var up := right.cross(fwd).normalized()
		var half_v := tan(deg_to_rad(ChaseCamera.BASE_FOV) * 0.5)
		var half_h := half_v * (16.0 / 9.0)
		# doar jumatatea DREAPTA a cadrului, unde trebuie sa fie faleza
		var hist := {}
		var hits := 0
		for r in 24:
			var sv := (float(r) + 0.5) / 24.0 * 2.0 - 1.0
			for c in 24:
				var sh := (float(c) + 0.5) / 24.0        # 0..1 = jumatatea dreapta
				var rd := (fwd + right * (sh * half_h) - up * (sv * half_v)).normalized()
				var q := PhysicsRayQueryParameters3D.create(eye, eye + rd * 300.0)
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					continue
				var w: Vector3 = hit["position"]
				hits += 1
				# rulajul lateral fata de cel mai apropiat punct de traseu
				var bi := _closest(pts, w)
				var bp: Vector3 = pts[bi]
				var sd := s.side_at(bi % s.point_count())
				var off := (w - bp).dot(sd)
				var key := int(floor(off / 5.0)) * 5
				hist[key] = int(hist.get(key, 0)) + 1
		print("\n=== frac %.2f — unde cad razele din JUMATATEA DREAPTA (%d atingeri) ===" % [f, hits])
		var keys := hist.keys()
		keys.sort()
		for kk in keys:
			var pct := 100.0 * float(hist[kk]) / float(maxi(hits, 1))
			if pct >= 1.5:
				print("   rulaj %+4d..%+4d m: %5.1f%%  %s" % [kk, int(kk) + 5, pct, "#".repeat(int(pct / 2.0))])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _closest(pts: PackedVector3Array, w: Vector3) -> int:
	var best := 0
	var bd := INF
	for i in pts.size():
		var d := Vector2(pts[i].x - w.x, pts[i].z - w.z).length_squared()
		if d < bd:
			bd = d
			best = i
	return best
