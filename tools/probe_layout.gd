extends Node
## Garda de GEOMETRIE a traseului: lungime, raze de viraj, panta, distanta
## dintre ramuri, si sanatatea scurtaturilor.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLayout.tscn
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLayout.tscn -- --track=1
##
## Trebuie rulata ca SCENA, nu cu --script: are nevoie de autoload-uri.
##
## De ce exista: pe Dunele, un viraj cu raza mai mica decat jumatatea latimii
## soselei a facut asfaltul sa se plieze peste el insusi, iar masinile se
## adunau acolo la fiecare tur. Nu se vede in editor, nu se vede intr-un
## snapshot de sus, si nicio alta sonda nu se uita la asa ceva — probe_decor
## numara triunghiuri, probe_race conduce. Regula e simpla si a fost platita
## scump: RAZA > half_width, iar doua ramuri paralele la >= 2*half_width.
##
## Numerele NU sunt praguri de esec pentru toate pistele: unele au fost desenate
## inainte de regula si trec pe langa ea in cateva locuri fara sa deranjeze. De
## aceea verdictul e "PROBLEMA" doar pentru pista ceruta explicit cu --track.

## Sub atat, asfaltul incepe sa se plieze. Exprimat ca multiplu de half_width.
const MIN_RADIUS_FACTOR: float = 1.0
## Doua bucle paralele mai apropiate de atat se ating. Multiplu de half_width.
const MIN_SEPARATION_FACTOR: float = 2.0
## Panta peste care masina fie decoleaza involuntar, fie se tarie.
const MAX_SLOPE: float = 0.22
## Cate puncte coapte se sar cand se cauta o alta bucla a pistei, ca sa nu se
## compare un punct cu vecinii lui imediati (care sunt normal aproape).
const SELF_SKIP: int = 30
## De la ce diferenta de cota doua puncte apropiate in plan sunt ETAJE, nu o
## atingere: peste toleranta verticala a testului "pe sosea" (12 m), cu marja.
const STACK_MIN_DY: float = 14.0


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	var failed := false
	for i in GameState.TRACK_SCENES.size():
		if only >= 0 and i != only:
			continue
		var bad := await _check(i)
		if bad and (only < 0 or i == only):
			failed = true
	print("")
	print("VERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	get_tree().quit(1 if failed else 0)


func _check(idx: int) -> bool:
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	print("")
	# Numele scenei, nu idx + 1: indexul in TRACK_SCENES nu mai coincide cu
	# numarul din fisier de cand s-au sters piste din mijlocul listei.
	print("=== %s — %s (half_width %.1f) ===" % [
		GameState.TRACK_SCENES[idx].get_file().get_basename(),
		track.track_name, track.half_width])
	var problems := 0
	for ri in track.routes.size():
		problems += _check_route(track, ri)
	track.queue_free()
	await get_tree().process_frame
	return problems > 0


func _check_route(track: Track, ri: int) -> int:
	var r := track.routes[ri]
	var n := r.count()
	if n < 3:
		print("  ruta %d (%s): prea putine puncte (%d)" % [ri, r.label, n])
		return 1
	var problems := 0
	var length := r.length()

	# --- raza de viraj, din trei puncte consecutive la ~12 m distanta --------
	var step := maxi(1, int(12.0 / maxf(track.curve.bake_interval, 0.1)))
	var min_radius := INF
	var min_at := 0.0
	var tight := 0
	# Pragul se ia din latimea RUTEI, nu a pistei: o scurtatura ingusta are
	# voie cu viraje mai stranse, fiindca si asfaltul ei e mai ingust.
	var limit := r.half_width * MIN_RADIUS_FACTOR
	for i in n:
		if not r.closed and (i < step or i >= n - step):
			continue
		var a := r.baked[r.wrap_index(i - step)]
		var b := r.baked[i]
		var c := r.baked[r.wrap_index(i + step)]
		var rad := _circumradius(a, b, c)
		if rad < min_radius:
			min_radius = rad
			min_at = r.frac_at(i)
		if rad < limit:
			tight += 1
	if tight > 0:
		problems += 1

	# --- panta ---------------------------------------------------------------
	var max_slope := 0.0
	var slope_at := 0.0
	for i in n - 1:
		var d := r.baked[i].distance_to(r.baked[i + 1])
		if d < 0.01:
			continue
		var s := absf(r.baked[i + 1].y - r.baked[i].y) / d
		if s > max_slope:
			max_slope = s
			slope_at = r.frac_at(i)
	if max_slope > MAX_SLOPE:
		problems += 1

	# --- cat de aproape trece pista de ea insasi -----------------------------
	var min_sep := INF
	var sep_at := 0.0
	var sep_limit := r.half_width * MIN_SEPARATION_FACTOR
	# Pista peste pista: doua puncte apropiate in plan dar STIVUITE (pasaj pe
	# piloni peste un tronson anterior) nu se ating — se cere in schimb
	# separare VERTICALA de cel putin STACK_MIN_DY, altfel o masina de pe
	# etajul de jos "e pe sosea" si pe cel de sus (TrackRoute.ROAD_ABOVE_TOLERANCE).
	var min_dy := INF
	var dy_at := 0.0
	for i in range(0, n, 3):
		for j in range(i + SELF_SKIP, n - (SELF_SKIP if r.closed else 0), 3):
			var d := Vector2(r.baked[i].x - r.baked[j].x,
				r.baked[i].z - r.baked[j].z).length()
			var dy := absf(r.baked[i].y - r.baked[j].y)
			if d < sep_limit and dy >= STACK_MIN_DY:
				if dy < min_dy:
					min_dy = dy
					dy_at = r.frac_at(i)
				continue
			if d < min_sep:
				min_sep = d
				sep_at = r.frac_at(i)
	if min_sep < sep_limit:
		problems += 1

	var flag_r := "" if tight == 0 else "  <-- %d puncte sub %.1f m" % [tight, limit]
	var flag_s := "" if max_slope <= MAX_SLOPE else "  <-- peste %.2f" % MAX_SLOPE
	var flag_sep := "" if min_sep >= sep_limit \
		else "  <-- sub %.1f m" % sep_limit
	print("  ruta %d  %-18s  %7.1f m  %4d puncte" % [ri, r.label, length, n])
	print("      raza minima     %7.1f m la frac %.2f%s"
		% [min_radius, min_at, flag_r])
	print("      panta maxima    %7.1f %% la frac %.2f%s"
		% [max_slope * 100.0, slope_at, flag_s])
	if min_sep < INF:
		print("      apropiere de sine %5.1f m la frac %.2f%s"
			% [min_sep, sep_at, flag_sep])
	if min_dy < INF:
		print("      stiva (pista peste pista): separare verticala minima %5.1f m la frac %.2f (prag %.0f)"
			% [min_dy, dy_at, STACK_MIN_DY])
	if ri > 0:
		# Scurtatura: capetele trebuie sa cada FIX pe sosea, altfel racordul e o
		# treapta in aer. Si trebuie sa fie mai scurta decat portiunea ocolita,
		# altfel n-are niciun rost.
		# O banda `elevated` se racordeaza la MARGINEA soselei, nu la axa
		# (Track._branch_end): acolo distanta corecta e fata de margine.
		# Exceptie: banda care si-a pus singura capetele (`own_ends`) le-a pus
		# pe AXA, si atunci fata de axa se si masoara — vezi TrackRoute.own_ends.
		var main := track.routes[0]
		var i_in := main.closest_index_global(r.baked[0])
		var i_out := main.closest_index_global(r.baked[n - 1])
		var d_in := main.lateral_distance(i_in, r.baked[0])
		var d_out := main.lateral_distance(i_out, r.baked[n - 1])
		if r.elevated and not r.own_ends:
			d_in = absf(d_in - track.width_at_index(i_in))
			d_out = absf(d_out - track.width_at_index(i_out))
		var span := r.exit_frac - r.entry_frac
		if span < 0.0:
			span += 1.0
		var bypassed := main.length() * span
		var gain := bypassed - length
		# [b]O banda de PEDEAPSA e mai lunga prin contract.[/b] Toate benzile
		# secundare de pana acum au fost scurtaturi — le iei ca sa castigi —
		# deci „mai lunga decat portiunea ocolita" insemna o banda fara rost.
		# Ocolul unui pasaj rotativ e pe dos: il iei doar cand banda directa e
		# INCHISA, si brief-ul ii cere explicit un cost (+3 s). A pretinde
		# castig pozitiv acolo ar fi a cere ca pedeapsa sa nu existe.
		#
		# Scutirea e strict pe steagul `TrackRoute.detour`, pus de banda insasi:
		# o banda fara el ramane cazuta daca e mai lunga, exact ca inainte.
		# [b]Si ocolul unui HAZARD care INCHIDE banda directa e mai lung prin
		# contract[/b] — gatul cu piatra de moara din Cappadocia (brief par. 2
		# POI F): culoarul scurt e o usa pe care piatra o inchide ciclic,
		# culoarul lung e "mereu liber, +2.5 s". A cere castig pozitiv aici ar
		# fi a cere ca decizia scurt-cu-risc / lung-sigur sa nu existe.
		# Scutirea nu e un steag scris de mana: se DERIVA din pista — exista un
		# hazard declarat pe chiar portiunea pe care banda o ocoleste.
		var hazard_bypassed := false
		for hz: Dictionary in track._node_hazards():
			var hf := fposmod(float(hz.get("frac", -1.0)), 1.0)
			var rel := hf - r.entry_frac
			if rel < 0.0:
				rel += 1.0
			if rel <= span:
				hazard_bypassed = true
				break
		var flag_gain := ""
		if r.detour:
			flag_gain = "  (ocol de PEDEAPSA: mai lung prin contract)"
		elif hazard_bypassed and gain <= 0.0:
			flag_gain = "  (ocol de SIGURANTA: hazard pe banda directa, mai lung prin contract)"
		elif gain <= 0.0:
			flag_gain = "  <-- MAI LUNGA decat ocolul"
		print("      racord intrare  %7.2f m  iesire %.2f m" % [d_in, d_out])
		print("      capete: (%.0f, %.1f, %.0f) -> (%.0f, %.1f, %.0f)"
			% [r.baked[0].x, r.baked[0].y, r.baked[0].z,
				r.baked[n - 1].x, r.baked[n - 1].y, r.baked[n - 1].z])
		print("      coarda directa  %7.0f m" % r.baked[0].distance_to(
			r.baked[n - 1]))
		print("      ocoleste %.0f m, are %.0f m -> castig %.0f m (%.0f%%)%s"
			% [bypassed, length, gain, gain / maxf(bypassed, 1.0) * 100.0,
				flag_gain])
		var longer_bad := gain <= 0.0 and not r.detour and not hazard_bypassed
		if d_in > 1.0 or d_out > 1.0 or longer_bad:
			problems += 1
	return problems


## Raza cercului prin trei puncte, in plan XZ. INF pentru puncte coliniare.
func _circumradius(a: Vector3, b: Vector3, c: Vector3) -> float:
	var p := Vector2(a.x, a.z)
	var q := Vector2(b.x, b.z)
	var s := Vector2(c.x, c.z)
	var ab := p.distance_to(q)
	var bc := q.distance_to(s)
	var ca := s.distance_to(p)
	# de doua ori aria triunghiului, cu semn
	var area2 := absf((q.x - p.x) * (s.y - p.y) - (s.x - p.x) * (q.y - p.y))
	if area2 < 1e-6:
		return INF
	return ab * bc * ca / (2.0 * area2)
