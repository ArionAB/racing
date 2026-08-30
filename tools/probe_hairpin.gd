extends Node
## La 0.24 raza exterioara pleaca spre interiorul buclei. Cat de aproape trece
## alt tronson al pistei de fiecare punct de pe raza?
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	for f in [0.22, 0.24, 0.26]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		print("--- frac %.2f  drum(%.0f,%.0f) y=%.1f" % [f, p.x, p.z, p.y])
		for d in [15.0, 40.0, 80.0, 150.0]:
			var q: Vector3 = p + side * d
			# cel mai apropiat alt punct al traseului (sarind vecinatatea)
			var best := INF; var bi := -1
			for j in n:
				var dj: int = absi(j - i); dj = mini(dj, n - dj)
				if dj < int(0.03 * n): continue
				var dd := Vector2(q.x - r.baked[j].x, q.z - r.baked[j].z).length()
				if dd < best: best = dd; bi = j
			print("   +%3dm (%.0f,%.0f) alt tronson la %.0f m (frac %.3f, y=%.1f)"
				% [int(d), q.x, q.z, best, float(bi) / n, r.baked[bi].y])
	get_tree().quit(0)
