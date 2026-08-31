extends Node
## De ce filtrul de parte refuza rapa la 0.24: pe linia laterala, care punct de
## drum e cel mai apropiat, la ce fractie sta el, si ce semn de parte iese.
## Daca `near_i` sare pe bratul de SUS al serpentinei, semnul se intoarce si
## rapa (declarata cu w=+1) se stinge — desi punctul e clar in vale.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var s = t._sampler
	print("=== FILTRUL DE PARTE PE LINIA LATERALA DE LA 0.24 ===")
	print("rapa 0 e declarata 0.175-0.40 cu w=+1, deci ACOPERA 0.24 pe hartie.")
	print("dist | near_frac | semn | teren | ce spune ravine_at(near_frac,+1)")
	for f in [0.22, 0.24, 0.26]:
		var i0 := int(f * n)
		var p: Vector3 = r.baked[i0]
		var a: Vector3 = r.baked[(i0 + 4) % n]
		var dir: Vector3 = (a - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()
		print("--- frac %.2f  (%.0f,%.0f) y=%.1f" % [f, p.x, p.z, p.y])
		for d in [10.0, 20.0, 30.0, 45.0, 60.0, 90.0, 130.0]:
			var q: Vector3 = p + side * d
			# reproduc cautarea celui mai apropiat punct copt
			var best := INF
			var bi := 0
			var j := 0
			while j < n:
				var dd := Vector2(q.x - r.baked[j].x, q.z - r.baked[j].z).length_squared()
				if dd < best:
					best = dd
					bi = j
				j += 3
			var nf := float(bi) / float(n)
			# semnul de parte fata de punctul acela
			var pb: Vector3 = r.baked[bi]
			var ab: Vector3 = r.baked[(bi + 4) % n]
			var db: Vector3 = (ab - pb).normalized()
			var sb: Vector3 = db.cross(Vector3.UP).normalized()
			var sgn := signf(Vector2(sb.x, sb.z).dot(Vector2(q.x - pb.x, q.z - pb.z)))
			var inside: bool = s.ravine_at(nf, 1.0)
			print("  %5.0f m | near_frac %.3f la %5.1f m | semn %+.0f | rapa_activa %s"
				% [d, nf, sqrt(best), sgn, "DA" if (inside and sgn > 0.0) else "NU"])
	get_tree().quit(0)
