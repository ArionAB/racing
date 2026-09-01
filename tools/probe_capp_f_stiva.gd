extends SceneTree
## Cat de jos trece bucla de intoarcere a elicei (POI G) peste sala 2 din POI F.
##
## Sonda asta raspunde la intrebarea "cat de inalt poate fi tavanul salii aici?".
## Traseul Cappadociei se suprapune cu el insusi: la frac 0.750 drumul e in
## (-335, 12.2, -16.0), iar la 0.845 in (-319, 26.6, -16.0) — acelasi z, 14.9 m
## mai sus. `ProbeLayout` vede suprapunerea (separare minima 15.1 m la frac 0.75,
## prag 14) dar nu spune ce INCAPE dedesubt.
##
## Concluzia masurata: sala 2 nu poate depasi frac ~0.75 cu tavan de 18 m, oricat
## ar cere briefu (§2 POI F cere 0.66-0.82). Peste 0.75 tavanul ar trece prin
## carosabilul de deasupra. Extinderea salii acolo e o decizie de TRASEU (coboara
## tavanul sub 14 m, sau muta bucla), nu de decor.
func _init() -> void:
	var tr := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	get_root().add_child(tr); await process_frame
	var pts = tr.route_at(0).baked
	var n = pts.size()
	var f := 0.720
	while f <= 0.790:
		var i: int = int(round(f * float(n))) % n
		var p: Vector3 = pts[i]
		var best := 1e9
		var bf := -1.0
		for j in range(n):
			var q: Vector3 = pts[j]
			if q.y <= p.y + 2.0: continue
			var d := Vector2(q.x - p.x, q.z - p.z).length()
			if d < 14.0 and (q.y - p.y) < best:
				best = q.y - p.y
				bf = float(j) / float(n)
		if bf < 0.0:
			print("%.3f  y=%5.2f  nimic deasupra" % [f, p.y])
		else:
			print("%.3f  y=%5.2f  bucla la +%.2f m (frac %.3f)  -> tavan max %.1f" % [f, p.y, best, bf, best - 2.0])
		f += 0.005
	quit()
