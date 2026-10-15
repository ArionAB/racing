extends Node
## MASOARA CE E INTR-UN PUNCT de pe Track22, in loc sa ghiceşti.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHlPoint.tscn \
##       -- --at=61,-196 [--span=12] [--track=22]
##
## De ce exista (brief §7.1, defectul 4): ProbeRace dadea 2-5 repuneri pe
## fiecare seed, toate la frac 0.801, toate in ACELASI punct. Am diagnosticat
## greşit de DOUA ori pe baza formei traseului (am ingustat rapa canalului, am
## largit podetul) si cifra n-a miscat de niciuna. Sonda asta a dat raspunsul
## din prima: un `@AnimatableBody3D@64` pe carosabil — colizorul placeholder al
## joncii fara model (vezi memoria `hazard-fara-model-e-zid-invizibil`).
##
## Regula de metoda: cand repunerile cad mereu in acelasi punct, defectul NU e
## de forma. Masoara ce e acolo: raycast vertical pe mai multe laterale (gaseste
## gauri si praguri) plus inventarul nodurilor din jur (gaseste corpuri fizice
## care n-ar trebui sa fie acolo).

const DEFAULT_SPAN := 12.0
const RAY_TOP := 60.0
const RAY_LEN := 140.0


func _ready() -> void:
	var at := Vector2(61.0, -196.0)
	var span := DEFAULT_SPAN
	var track_no := 22
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var parts := a.substr(5).split(",")
			if parts.size() == 2:
				at = Vector2(float(parts[0]), float(parts[1]))
		elif a.begins_with("--span="):
			span = float(a.substr(7))
		elif a.begins_with("--track="):
			track_no = int(a.substr(8))

	var path := "res://scenes/tracks/Track%02d.tscn" % track_no
	var packed := load(path) as PackedScene
	if packed == null:
		print("nu pot incarca ", path)
		get_tree().quit(1)
		return
	var track := packed.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var center := Vector3(at.x, 0.0, at.y)
	print("=== ProbeHlPoint: %s la (%.0f, ?, %.0f), span +/-%.0f m ==="
		% [path.get_file(), at.x, at.y, span])

	# 1. RAYCAST VERTICAL pe o cruce de puncte: gaseste gauri, praguri, cote.
	var space := get_viewport().world_3d.direct_space_state
	print("\n--- raycast vertical (cota si ce s-a lovit) ---")
	var hits: Array[float] = []
	# Buclele sunt TIPIZATE anume: iterand peste un array literal netipizat,
	# `var p := center + axis * off` nu-si poate infera tipul si scriptul NU
	# COMPILEAZA ("Cannot infer the type of p"). Prima versiune a fost comisa
	# asa si n-a rulat niciodata — iar o sonda care nu ruleaza arata exact ca
	# una care nu gaseste nimic (memoria `garda-verde-pe-zero-masuratori`).
	var offs: Array[float] = [-span, -span * 0.66, -span * 0.33, 0.0,
		span * 0.33, span * 0.66, span]
	var axes: Array[Vector3] = [Vector3(1, 0, 0), Vector3(0, 0, 1)]
	for off: float in offs:
		for axis: Vector3 in axes:
			var p: Vector3 = center + axis * off + Vector3.UP * RAY_TOP
			var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * RAY_LEN)
			var hit := space.intersect_ray(q)
			var tag := "x" if axis.x != 0.0 else "z"
			if hit.is_empty():
				print("  %s %+6.1f m: NIMIC (gol pe %.0f m in jos)" % [tag, off, RAY_LEN])
			else:
				var col := hit.get("collider") as Node
				var y := float(hit["position"].y)
				hits.append(y)
				print("  %s %+6.1f m: y=%6.2f   %s" % [tag, off, y,
					col.name if col != null else "?"])
	if hits.size() >= 2:
		hits.sort()
		var spread := hits[hits.size() - 1] - hits[0]
		print("  -> imprastiere de cote: %.2f m %s" % [spread,
			"(PRAG/GAURA: peste 0.3 m e zid)" if spread > 0.3 else "(plan)"])

	# 2. CORPURI FIZICE in jur: gaseste ce n-ar trebui sa fie pe drum.
	print("\n--- corpuri fizice la < %.0f m (cauta ce n-are ce cauta pe drum) ---"
		% (span * 4.0))
	var found := 0
	for n in track.find_children("*", "PhysicsBody3D", true, false):
		var b := n as Node3D
		if b == null:
			continue
		var d := Vector2(b.global_position.x - at.x, b.global_position.z - at.y).length()
		if d > span * 4.0:
			continue
		found += 1
		print("  %-28s la (%.1f, %.2f, %.1f)  d=%.1f m  [%s]"
			% [b.name, b.global_position.x, b.global_position.y, b.global_position.z,
				d, b.get_class()])
	# GABARITUL corpurilor mobile: cat ocupa efectiv din drum. La un hazard de
	# traversare asta e cifra care decide daca mai rămâne banda libera.
	print("\n--- gabaritul corpurilor mobile (cat din drum ocupa) ---")
	# Latimea drumului in punctul masurat: din raycast-urile de mai sus, nu
	# presupusa. Cea mai larga intindere pe care s-a lovit `RoadTop`.
	var road_total := _road_width_at(space, center, span)
	print("  latimea drumului masurata aici: %.1f m" % road_total)
	var any_mobile := false
	for n in track.find_children("*", "AnimatableBody3D", true, false):
		var b := n as Node3D
		if b == null:
			continue
		var d := Vector2(b.global_position.x - at.x, b.global_position.z - at.y).length()
		if d > span * 4.0:
			continue
		any_mobile = true
		var aabb := Track.model_aabb(b)
		print("  %s: %.2f x %.2f x %.2f m (lung x inalt x lat)"
			% [b.name, aabb.size.x, aabb.size.y, aabb.size.z])
		var footprint := maxf(aabb.size.x, aabb.size.z)
		# LATIMEA TOTALA a drumului, nu semi-latimea: un corp de 9 m pe un drum
		# de 2 x 6 m are 12 m de traversat, nu 6. (Prima versiune compara cu
		# semi-latimea si raporta "-2.32 m, acopera tot drumul", ceea ce era
		# fals cu un factor de doi.)
		print("    -> amprenta max %.2f m pe drum de %.0f m total (2 x %.0f)"
			% [footprint, road_total, road_total * 0.5])
		var free := road_total - footprint
		print("       banda libera cand corpul e pe axa: %.2f m" % free)
		if free < 1.0:
			print("       !! ACOPERA TOT DRUMUL: nicio banda libera")
		elif free < 3.0:
			print("       !  banda strimta (< 3 m): trecerea e la limita")
	if not any_mobile:
		print("  (niciun corp mobil in zona)")

	if found == 0:
		print("  (niciunul)")
	else:
		print("  -> un corp care traverseaza carosabilul e obstacol SOLID: la")
		print("     SlidingHazard/TRAVERSARE e prin design, deci repunerile pe el")
		print("     sunt reglaj de hazard, nu defect de traseu")

	# O sonda care n-a masurat NIMIC nu are voie sa iasa cu cod 0: ar arata
	# identic cu una care n-a gasit nimic de raportat (memoria
	# `garda-verde-pe-zero-masuratori`).
	if hits.is_empty():
		print("\nPICAT: niciun raycast n-a lovit nimic — punctul e in afara lumii,")
		print("       sau pista nu s-a construit. Nu e un rezultat, e o sonda goala.")
		get_tree().quit(1)
		return
	print("\n(%d raycast-uri au lovit; sonda a masurat ceva)" % hits.size())
	get_tree().quit(0)


## Latimea carosabilului in punctul dat, MASURATA.
##
## Baleiajul trebuie facut PERPENDICULAR pe direcţia drumului, nu pe axele
## lumii: pe o axa aliniata cu sensul de mers, `RoadTop` continua pe sute de
## metri si masuratoarea iese absurd (prima versiune a raportat 48 m pe un drum
## de 12). Direcţia o dau cele doua laturi ale drumului: caut unghiul pe care
## latimea e MINIMA — aia e normala la ax.
func _road_width_at(space: PhysicsDirectSpaceState3D, center: Vector3,
		span: float) -> float:
	var best := INF
	for deg in range(0, 180, 10):
		var a := deg_to_rad(float(deg))
		var axis := Vector3(cos(a), 0.0, sin(a))
		var reach_pos := 0.0
		var reach_neg := 0.0
		var step := 0.5
		var d := step
		while d <= span * 2.5:
			for sign_: float in [1.0, -1.0]:
				var p: Vector3 = center + axis * (d * sign_) + Vector3.UP * RAY_TOP
				var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * RAY_LEN)
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					continue
				var col := hit.get("collider") as Node
				if col == null or not String(col.name).begins_with("RoadTop"):
					continue
				if sign_ > 0.0:
					reach_pos = maxf(reach_pos, d)
				else:
					reach_neg = maxf(reach_neg, d)
			d += step
		var w := reach_pos + reach_neg
		if w > 1.0:
			best = minf(best, w)
	return 0.0 if is_inf(best) else best
