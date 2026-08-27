extends Node
## Cautare completa: pentru fiecare fractie candidat, fiecare parte si fiecare
## offset, distanta minima de la talpa la ORICE punct al rutei aflat la
## +-11 m cota (inaltimea la care mastul chiar bareaza). Nu se sare niciun
## punct: drumul se intoarce pe langa turn in POI F.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 8:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var need := 1.8 + 7.0 + 0.95
	print("cerut %.2f m; se cauta marja > 2 m" % need)
	var found: Array = []
	var f := 0.700
	while f <= 0.830:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 3) % n] - r.baked[(i - 3 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		for sgn: float in [1.0, -1.0]:
			for off: float in [12.0, 16.0, 20.0, 26.0]:
				var mast := c + side * off * sgn
				var best := 1e9
				for j in n:
					var p: Vector3 = r.baked[j]
					if p.y < mast.y - 11.0 or p.y > mast.y + 24.0:
						continue
					best = minf(best, Vector2(p.x - mast.x, p.z - mast.z).length())
				if best - need > 2.0:
					found.append([f, sgn, off, best - need])
		f += 0.005
	found.sort_custom(func(a, b): return a[3] > b[3])
	for k in mini(12, found.size()):
		var e = found[k]
		print("  frac %.3f  side %+.0f  off %2.0f  ->  marja %+.2f m" % [e[0], e[1], e[2], e[3]])
	if found.is_empty():
		print("  NICIUN loc in POI F nu lasa turnul liber.")
	get_tree().quit()
