extends Node
## SONDA POI-ului C (Cappadocia, cornisa Vaii Rosii): geometria REALA a locului
## in care se aseaza baloanele, masurata pe Track13, nu desenata din ochi.
##
## Intrebarea practica: unde poate sta un tarus de balon astfel incat cosul care
## urca 30 m sa ajunga CHIAR in banda? Raspunsul cere trei cifre pe fiecare
## fractie de cornisa, si toate trei vin din teren:
##   - unde se termina asfaltul (semilatimea de acolo),
##   - de la cati metri lateral terenul e sub cota unei polite utile,
##   - pana la cati metri lateral coloana verticala de 30 m e libera.
##
## Cifra care decide e `half_width + BASKET/2` (masurata in ProbeBalloon:
## 7.0 + 2.4 = 9.4 m): dincolo de ea cosul ajunge sus in gol, langa drum, si
## hazardul-semnatura nu exista.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCorniceC.tscn

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const BASKET_HALF: float = 2.4
## Cursa cosului, pentru verificarea coloanei libere.
const RISE: float = 30.0
## Cornisa: rapa 0 din Track13.tscn.
const F0: float = 0.185
const F1: float = 0.38
const SIDE: float = 1.0
const MAX_OFFSET: float = 40.0

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var sampler: TrackSideSampler = _track.get("_sampler")
	var n := _track.baked.size()
	print("=== POI C: geometria cornisei Vaii Rosii (Track13, rapa 0) ===")
	print("  cornisa frac %.3f..%.3f, latura %+.0f; cosul cere tarusul la <= half+%.1f m"
		% [F0, F1, SIDE, BASKET_HALF])
	print("  frac | idx | half | lane_y | podea_la | culoar_liber | fund_y")
	_trace(sampler, n, 0.265)
	_ledge_report(sampler, n)
	_stake_report(sampler, n)
	_shelf_scan(sampler, n)
	_who_blocks(sampler, n, 0.265, 9.4)
	_verdict_baskets(sampler, n)
	var f := F0
	while f <= F1 + 0.0001:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var sd: Vector3 = sampler.side_at(i) * SIDE
		var half := sampler.half_width_at(i)
		var floor_off := MAX_OFFSET
		var clear_off := MAX_OFFSET
		var floor_y := 0.0
		for k in int(MAX_OFFSET) + 1:
			var off := float(k)
			var q := p + sd * off
			var g := sampler.ground_y(q.x, q.z)
			# „Polita utila": teren cu cel putin 8 m sub cota drumului, adica
			# deja in faleza, nu pe umarul asfaltului.
			if floor_off >= MAX_OFFSET and g < p.y - 8.0:
				floor_off = off
				floor_y = g
			if clear_off >= MAX_OFFSET and g < p.y - 8.0 and _column_clear(q, sd, g):
				clear_off = off
		print("  %.3f | %3d | %4.1f | %6.2f | %8.1f | %12.1f | %6.2f"
			% [f, i, half, p.y, floor_off, clear_off, floor_y])
		f += 0.01
	_track.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


## VERDICTUL POI-ului C: cele trei baloane din scena chiar ajung cu cosul IN
## banda? Se citesc nodurile reale din Track13 (nu se re-calculeaza nimic), se
## ia cota lor de varf si se compara marginea cosului dinspre drum cu marginea
## asfaltului. Asta e intrebarea (vi) a lui ProbeBalloon, pusa pe pista reala.
func _verdict_baskets(sampler: TrackSideSampler, n: int) -> void:
	print("  --- VERDICT: ajung cosurile in banda? (nodurile reale din Track13) ---")
	var group := _track.get_node_or_null("DecorManual/C) Cornisa Vaii Rosii")
	if group == null:
		print("    (fara DecorManual)")
		return
	var fails := 0
	var seen := 0
	for child in group.get_children():
		if not (child is BalloonHazard):
			continue
		seen += 1
		var h := child as BalloonHazard
		var top := h.top_y()
		var pos := h.global_position
		# Indexul de banda cel mai apropiat, si distanta laterala fata de ax.
		var i := _track.closest_index_global(pos, 0)
		var lp: Vector3 = _track.baked[i]
		var sd: Vector3 = sampler.side_at(i) * SIDE
		var off := Vector2(sd.x, sd.z).dot(Vector2(pos.x - lp.x, pos.z - lp.z))
		var half := sampler.half_width_at(i)
		var inner := off - BASKET_HALF
		var gap := inner - half
		var lane_ok := absf(top - (lp.y + 0.8)) < 1.5
		var reach_ok := gap <= 0.0
		if not (lane_ok and reach_ok):
			fails += 1
		print("    %s: tarus y=%.2f, varf y=%.2f (banda %.2f) | off %.2f m, half %.1f -> %s | cota %s"
			% [child.name, h.base_y(), top, lp.y, off, half,
				("suprapune banda cu %.2f m" % -gap) if reach_ok
					else ("ramane %.2f m de gol" % gap),
				"OK" if lane_ok else "GRESITA"])
	print("    => %d baloane, %d picate" % [seen, fails])


## Cine anume infunda coloana, cota cu cota: numele corpului si cota terenului
## chiar acolo. Fara asta „infundata" e un cuvant, nu o cauza.
func _who_blocks(sampler: TrackSideSampler, n: int, f: float, off: float) -> void:
	var i := int(f * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var sd: Vector3 = sampler.side_at(i) * SIDE
	var q := p + sd * off
	var space := get_viewport().world_3d.direct_space_state
	print("  --- cine infunda coloana la frac %.3f, off %.1f m (drum y=%.2f) ---"
		% [f, off, p.y])
	var y := 14.0
	while y <= p.y + 2.0:
		var names: Array[String] = []
		for lat: float in [-BASKET_HALF, 0.0, BASKET_HALF]:
			var c := Vector3(q.x, y, q.z) + sd * lat
			var rq := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			var hit := space.intersect_ray(rq)
			names.append("-" if hit.is_empty() else (hit["collider"] as Node).name
				+ "@%.1f" % lat)
		print("    y=%6.2f | %s" % [y, " ".join(names)])
		y += 2.0


## POLITA IN FALEZA: cat de SUS trebuie sa fie o polita la `off` metri de ax ca
## sa aiba coloana libera pana la banda? Asta e solutia pe care o cere
## docs/track_briefs/cappadocia_geometrie.md: tarusul nu pe fundul vaii, ci pe o
## polita in peretele falezei. Aici se masoara cota minima a ei.
func _shelf_scan(sampler: TrackSideSampler, n: int) -> void:
	print("  --- POLITA IN FALEZA: cota minima cu coloana libera pana la banda ---")
	for f: float in [0.205, 0.225, 0.245, 0.265, 0.285, 0.305, 0.325, 0.345]:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var sd: Vector3 = sampler.side_at(i) * SIDE
		for off: float in [7.6, 8.6, 9.4]:
			var q := p + sd * off
			var best := -1.0
			var y := 13.7
			while y < p.y - 2.0:
				if _clear_to(q, sd, y, p.y + 2.0):
					best = y
					break
				y += 0.5
			print("    frac %.3f off %.1f m: polita minima la y=%s (cursa %s)"
				% [f, off, "-" if best < 0.0 else "%.1f" % best,
					"-" if best < 0.0 else "%.1f m" % (p.y - best)])


## Coordonatele de LUME ale unei polite taiate la `off` metri de ax, pentru
## fiecare fractie de interes: acolo se pune tarusul in .tscn.
func _stake_report(sampler: TrackSideSampler, n: int) -> void:
	print("  --- coordonate de tarus (off = 8.6 m de ax, pe polita taiata) ---")
	for f: float in [0.205, 0.245, 0.285, 0.325, 0.345]:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var sd: Vector3 = sampler.side_at(i) * SIDE
		var off := 8.6
		var q := p + sd * off
		var g := sampler.ground_y(q.x, q.z)
		var clear := _clear_to(q, sd, g, p.y + 2.0)
		# unde se infunda, daca se infunda
		var space := get_viewport().world_3d.direct_space_state
		var stop := 0.0
		var kk := g + 1.0
		while kk <= p.y + 2.0:
			var bad := false
			for lat: float in [-BASKET_HALF, 0.0, BASKET_HALF]:
				var c := Vector3(q.x, kk, q.z) + sd * lat
				var rq := PhysicsRayQueryParameters3D.create(
					c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
				if not space.intersect_ray(rq).is_empty():
					bad = true
			if bad and stop == 0.0:
				stop = kk
			kk += 1.0
		print("    frac %.3f idx %3d: banda (%.2f, %.2f, %.2f) | tarus (%.2f, %.2f, %.2f) | cursa %.2f | coloana %s"
			% [f, i, p.x, p.y, p.z, q.x, g, q.z, p.y - g,
				"LIBERA" if clear else "infundata la y=%.1f" % stop])


## POLITA: pentru fiecare fractie, cea mai apropiata polita de ax pe care
## coloana verticala e libera pana la cota benzii. Asta e cifra care spune daca
## hazardul-semnatura poate exista aici — vezi ProbeBalloon (vi).
func _ledge_report(sampler: TrackSideSampler, n: int) -> void:
	var limit := 7.0 + BASKET_HALF
	print("  --- POLITA cu coloana libera pana la banda (limita %.1f m de ax) ---" % limit)
	var f := F0 + 0.01
	while f <= F1 - 0.01:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var sd: Vector3 = sampler.side_at(i) * SIDE
		var best := -1.0
		var best_y := 0.0
		for k in 20:
			var off := float(k)
			var q := p + sd * off
			var g := sampler.ground_y(q.x, q.z)
			if g > p.y - 8.0:
				continue
			# Coloana de la polita pana la 2 m PESTE cota benzii: cosul trebuie
			# sa ajunga in banda, nu doar sa urce liber o bucata.
			if _clear_to(q, sd, g, p.y + 2.0):
				best = off
				best_y = g
				break
		print("    frac %.3f: polita la %s (y=%.2f, cursa %.1f m)"
			% [f, "-" if best < 0.0 else "%.1f m" % best, best_y,
				0.0 if best < 0.0 else p.y - best_y])
		f += 0.02


## Coloana libera de la `from_y` pana la `to_y`, pe latimea cosului.
func _clear_to(at: Vector3, sd: Vector3, from_y: float, to_y: float) -> bool:
	var space := get_viewport().world_3d.direct_space_state
	var k := from_y + 1.0
	while k <= to_y:
		for lat: float in [-BASKET_HALF, 0.0, BASKET_HALF]:
			var c := Vector3(at.x, k, at.z) + sd * lat
			var q := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			if not space.intersect_ray(q).is_empty():
				return false
		k += 1.0
	return true


## Profilul lateral detaliat la o fractie, cu ce anume infunda coloana.
func _trace(sampler: TrackSideSampler, n: int, f: float) -> void:
	var i := int(f * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var sd: Vector3 = sampler.side_at(i) * SIDE
	var space := get_viewport().world_3d.direct_space_state
	print("  --- profil detaliat la frac %.3f (drum y=%.2f) ---" % [f, p.y])
	for k in 25:
		var off := float(k)
		var q := p + sd * off
		var g := sampler.ground_y(q.x, q.z)
		var blk := "-"
		var blk_y := 0.0
		for m in int(RISE):
			var y := g + 1.0 + float(m)
			for lat: float in [-BASKET_HALF, 0.0, BASKET_HALF]:
				var c := Vector3(q.x, y, q.z) + sd * lat
				var rq := PhysicsRayQueryParameters3D.create(
					c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
				var hit := space.intersect_ray(rq)
				if not hit.is_empty() and blk == "-":
					blk = (hit["collider"] as Node).name
					blk_y = y
		print("    %5.1f m -> teren y=%7.2f (drum%+7.2f) | coloana: %s %s"
			% [off, g, g - p.y, blk, "" if blk == "-" else "la y=%.1f (+%.1f)" % [blk_y, blk_y - g]])


## E libera coloana de `RISE` metri de deasupra punctului, pe latimea cosului?
func _column_clear(at: Vector3, sd: Vector3, from_y: float) -> bool:
	var space := get_viewport().world_3d.direct_space_state
	for k in int(RISE):
		var y := from_y + 1.0 + float(k)
		for lat: float in [-BASKET_HALF, 0.0, BASKET_HALF]:
			var c := Vector3(at.x, y, at.z) + sd * lat
			var q := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			if not space.intersect_ray(q).is_empty():
				return false
	return true
