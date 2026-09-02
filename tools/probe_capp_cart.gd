extends Node
## Sonda pentru CARUTA CU OALE de la iesirea din piata (POI A, frac 0.030):
## blocajul chiar lasa o fanta de 4 m, si — intrebarea care conteaza de fapt —
## o masina care intra in el NU RAMANE AGATATA.
##
## De ce nu ajunge `probe_solid`: ala plimba gabaritul pe AXUL benzii si cere
## drum liber peste tot. Aici drumul e blocat INTENTIONAT pe 14 din cei 18 m,
## deci pe ax sonda aia trebuie sa gaseasca ceva. Ce trebuie masurat e altceva:
##   (a) cat de lat e golul real, masurat cu gabaritul masinii, nu pe AABB-uri
##       (capcana din `decor-manual-coliziune`);
##   (b) blocajul e CONVEX — adica nu exista niciun buzunar in care botul sa
##       intre si sa nu mai iasa. Un U cu deschiderea spre drum ar trece de
##       testul (a) si tot ar bloca cursa (lectia
##       `coliziune-contact-si-platforma`).
##
## (b) se masoara plimband gabaritul PE LANGA blocaj, in lungul lui: daca
## profilul de adancime la care se opreste masina are un MINIM LOCAL inconjurat
## de valori mai mari, aia e o gaura. Un obstacol convex da un profil monoton.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappCart.tscn -- --track=6
##
## Cod de iesire 1 daca fanta e sub 3.5 m sau daca apare un buzunar.

## Gabaritul masinii, ca la `probe_solid`.
const CAR_WIDTH: float = 2.4
const CAR_HEIGHT: float = 1.4
const CAR_LENGTH: float = 4.0

## Fractia unde sta blocajul (aceeasi ca in gen_decor_capp_a.gd).
const CART_FRAC: float = 0.0300

## Fanta ceruta de brief §2 A, cu toleranta de masurare.
const GAP_MIN: float = 3.5

var _fail := false


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame

	var n := track.baked.size()
	var i := int(CART_FRAC * float(n)) % n
	var p := track.baked[i]
	var s := track._side_at(i)
	var half := track.width_at_index(i)
	var dir := (track.baked[(i + 1) % n] - p).normalized()
	print("")
	print("=== caruta cu oale: frac %.4f, ax=(%.2f, %.2f, %.2f), half_w=%.2f ===" % [
		CART_FRAC, p.x, p.y, p.z, half])

	var space := track.get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(CAR_WIDTH, CAR_HEIGHT, CAR_LENGTH)

	# (a) FANTA. Se plimba gabaritul pe latimea benzii si se noteaza unde
	# incape. Pasul e 0.25 m: mai fin decat marja pe care o cauta briefull.
	print("")
	print("--- (a) unde incape masina pe latimea benzii ---")
	var free: Array[float] = []
	var lat := -half
	while lat <= half + 0.001:
		var q := p + s * lat + Vector3.UP * (0.15 + 0.5 * CAR_HEIGHT)
		if not _blocked(space, shape, q, dir):
			free.append(lat)
		lat += 0.25
	if free.is_empty():
		print("  BLOCAT COMPLET — nicio pozitie libera pe cei %.1f m" % (2.0 * half))
		_fail = true
	else:
		# Cel mai lat interval continuu de pozitii libere.
		var best_a := free[0]
		var best_b := free[0]
		var cur_a := free[0]
		var prev := free[0]
		for v in free:
			if v - prev > 0.30:
				cur_a = v
			elif v - best_b > 0.0 and prev - cur_a >= best_b - best_a:
				pass
			if prev - cur_a > best_b - best_a:
				best_a = cur_a
				best_b = prev
			prev = v
		if prev - cur_a > best_b - best_a:
			best_a = cur_a
			best_b = prev
		# Golul REAL include jumatatile de masina de la capete.
		var gap := (best_b - best_a) + CAR_WIDTH
		print("  centrul masinii incape pe %+.2f .. %+.2f m fata de ax" % [best_a, best_b])
		print("  fanta libera (cu latimea masinii) = %.2f m  [cerut >= %.1f]" % [gap, GAP_MIN])
		if gap < GAP_MIN:
			print("  ESEC: fanta prea ingusta")
			_fail = true

	# (b) BUZUNARE. Se impinge gabaritul catre blocaj din fata, pe fiecare
	# offset lateral, si se noteaza cat de departe ajunge inainte sa atinga.
	# Pe un obstacol convex profilul e neted; un minim local inconjurat de
	# valori mai mari inseamna o gaura in care intra botul.
	print("")
	print("--- (b) profilul de oprire (buzunare) ---")
	var depth: Array[float] = []
	var lats: Array[float] = []
	lat = -half
	while lat <= half + 0.001:
		var d := 0.0
		var t := -9.0
		while t <= 9.0:
			var q := p + s * lat + dir * t + Vector3.UP * (0.15 + 0.5 * CAR_HEIGHT)
			if _blocked(space, shape, q, dir):
				d = t
				break
			t += 0.25
			d = 99.0
		depth.append(d)
		lats.append(lat)
		lat += 0.5
	var pockets := 0
	for k in range(1, depth.size() - 1):
		# Un buzunar: masina ajunge MAI ADANC aici decat de o parte si de alta,
		# cu amandoua marginile solide (99 = liber, deci nu e perete).
		if depth[k] < 99.0 and depth[k - 1] < 99.0 and depth[k + 1] < 99.0:
			if depth[k] > depth[k - 1] + 1.0 and depth[k] > depth[k + 1] + 1.0:
				print("  BUZUNAR la %+.2f m: se intra %.2f m, vecinii %.2f / %.2f" % [
					lats[k], depth[k], depth[k - 1], depth[k + 1]])
				pockets += 1
	var row := "  adancime: "
	for k in depth.size():
		row += ("%5.1f" % depth[k]) if depth[k] < 99.0 else "  ---"
	print(row)
	if pockets == 0:
		print("  niciun buzunar: blocajul e convex, masina aluneca spre fanta")
	else:
		print("  ESEC: %d buzunare" % pockets)
		_fail = true

	print("")
	print("VERDICT: %s" % ("ESEC" if _fail else "OK"))
	get_tree().quit(1 if _fail else 0)


## Atinge gabaritul ceva in pozitia data?
func _blocked(space: PhysicsDirectSpaceState3D, shape: BoxShape3D,
		pos: Vector3, dir: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	var basis := Basis.looking_at(dir, Vector3.UP)
	q.transform = Transform3D(basis, pos)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	var hits := space.intersect_shape(q, 8)
	for h in hits:
		var c: Node = h["collider"]
		# Terenul si soseaua nu conteaza — masina merge PE ele.
		if c.name.begins_with("Terrain") or c.name.begins_with("Road"):
			continue
		if c is StaticBody3D and c.get_parent() != null \
				and c.get_parent().name.begins_with("Terrain"):
			continue
		return true
	return false
