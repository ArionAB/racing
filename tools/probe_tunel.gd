extends Node
## GARDA tunelului Homer (Fiordland, brief §2 rândul E): tubul EXISTĂ și are
## golul din contract — 9,0 m liber între pereți, 6,5 m sub tavan, pe toată
## lungimea lui `SemaforTunel.tunnel_length`, și terenul nu intră în el.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTunel.tscn -- --track=9
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTunel.tscn -- --track=9 --expect-tube
##
## Trebuie rulată ca SCENĂ (autoload-uri). `--track` e POZIȚIA din
## GameState.TRACK_SCENES sau numărul scenei (resolve_track_index).
##
## De ce există: dezvoltatorul a condus și a spus „tunelul nu există" — lampa,
## autocarul și logica de bandă erau montate, dar nu era nici tavan, nici
## perete, nici portal. Nicio sondă nu punea întrebarea „e un TUB acolo?":
## ProbeBuried întreabă doar terenul (și tunelul nu e teren), ProbeRace
## numără contacte, ProbeLayout citește curba. Memoria
## `garda-cu-numele-gimmickului`: contractul se scrie ca cifră față de bandă.
##
## Ce măsoară, din 10 în 10 m pe lungimea declarată de nod (începutul e
## originea nodului proiectată pe axă, exact ca `_rebuild_bus_curve`):
##
##   1. TERENUL față de cota drumului, pe axă și la ±6 / ±10 / ±15 m lateral
##      (doar corpurile `TerrainBody*`, fața cea mai de sus). Spune dacă
##      masivul e tranșee deschisă sau teren peste drum — și, după construcție,
##      dacă terenul intră în volumul tubului.
##   2. GOLUL, ca gol (memoria `cota-de-contract-se-masoara-ca-gol`): raze
##      laterale din axă la mai multe înălțimi (proiecția secțiunii pe plan,
##      eșantionată), până la primul corp lovit — lățimea liberă e suma
##      stânga + dreapta, minimul pe înălțimi. Tavanul: raze în sus de la
##      +0,3 m peste asfalt, pe toată lățimea contractului, minimul.
##   3. Cele două benzi: autocarul (3,0 m pe −2,4 → [−3,9, −0,9]) și mașina
##      pe +2,0 (semilățime 1,1 → [+0,9, +3,1]) trebuie să aibă aer până la
##      3,6 m înălțime, deci stânga liberă ≥ 3,9 și dreapta liberă ≥ 3,1 pe
##      toate înălțimile de sub 3,6 m.
##
## Verdict (cod 1 doar cu `--expect-tube`): tub prezent pe toate stațiile,
## lățime liberă ≥ 9,0 − TOL, tavan ≥ 6,5 − TOL, benzile libere.

const STEP_M: float = 10.0
const WIDTH_M: float = 9.0
const CEILING_M: float = 6.5
const TOL: float = 0.06
## Înălțimile la care se caută pereții (m peste asfalt). Ultima e chiar sub
## tavan: acolo o boltă rotunjită ar strânge golul, un tub drept nu.
const WALL_HEIGHTS: Array[float] = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.3]
## Cât de departe se caută lateral. Dincolo de atât nu e „perete de tunel".
const SIDE_REACH: float = 14.0
const UP_REACH: float = 14.0
const BUS_LEFT_M: float = 3.9
const CAR_RIGHT_M: float = 3.1
const LANE_TOP_M: float = 3.6
const TERRAIN_BODY: String = "TerrainBody"

var _expect_tube := false


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(9)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg == "--expect-tube":
			_expect_tube = true
	if idx < 0:
		push_error("ProbeTunel: index de pistă invalid")
		get_tree().quit(1)
		return
	var ok := await _check(idx)
	get_tree().quit(0 if (ok or not _expect_tube) else 1)


func _check(idx: int) -> bool:
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	print("")
	print("=== %s — tunel ===" % GameState.track_label(idx))

	var sig := _find_signal(track)
	if sig == null:
		print("  niciun TunnelSignalHazard pe pistă — nimic de măsurat")
		track.queue_free()
		return false
	var r := track.route_at(0)
	var n := r.baked.size()
	var line_idx: int = track.closest_index_global(sig.global_transform.origin, 0)
	var length: float = sig.tunnel_length
	# Aceeași plimbare ca `_rebuild_bus_curve`: pe distanța acumulată între
	# puncte coapte consecutive, nu pe un pas de index presupus.
	var idx_west := line_idx
	var acc := 0.0
	while acc < length and idx_west - line_idx < n:
		acc += r.baked[r.wrap_index(idx_west)].distance_to(
			r.baked[r.wrap_index(idx_west + 1)])
		idx_west += 1
	print("  nod la %s | line_idx %d (frac %.3f) -> idx_west %d (frac %.3f) | %.1f m pe %d indici | hw %.2f"
		% [sig.global_transform.origin, line_idx, r.frac_at(line_idx),
			r.wrap_index(idx_west), r.frac_at(r.wrap_index(idx_west)), acc,
			idx_west - line_idx, sig.tunnel_half_width])
	print("  cota drum: est %.2f -> vest %.2f (panta medie %.1f %%)"
		% [r.baked[line_idx].y, r.baked[r.wrap_index(idx_west)].y,
			100.0 * (r.baked[r.wrap_index(idx_west)].y - r.baked[line_idx].y) / maxf(acc, 1.0)])

	var terrain := _terrain_bodies(track)
	var cars: Array[Node] = []
	# Mijlocul tubului si vecinii lui in plan: unde ar trebui sa stea masivul si
	# ce alte bucati de traseu ar prinde un dom centrat acolo.
	var mid_idx: int = r.wrap_index((line_idx + idx_west) / 2)
	var mid: Vector3 = r.baked[mid_idx]
	print("  mijloc tub: idx %d frac %.3f la (%.1f, %.1f, %.1f)" % [mid_idx, r.frac_at(mid_idx), mid.x, mid.y, mid.z])
	for pk in track.find_children("*", "Marker3D", true, false):
		if pk is TerrainPeak:
			var pp: Vector3 = (pk as Node3D).global_position
			print("  varf %s la (%.1f, y %.1f, %.1f) raza %.0f | distanta in plan de mijloc %.1f m" % [pk.name, pp.x, pp.y, pp.z, (pk as TerrainPeak).radius_m, Vector2(pp.x - mid.x, pp.z - mid.z).length()])
	var best_d := INF
	var best_i := -1
	for i in n:
		if i >= line_idx - 60 and i <= idx_west + 60:
			continue
		var dd := Vector2(r.baked[i].x - mid.x, r.baked[i].z - mid.z).length()
		if dd < best_d:
			best_d = dd
			best_i = i
	if best_i >= 0:
		print("  cel mai apropiat traseu strain de mijloc (in afara +-60 indici): %.1f m la frac %.3f (y %.1f)" % [best_d, r.frac_at(best_i), r.baked[best_i].y])
	for radius: float in [60.0, 90.0, 120.0, 150.0]:
		var cnt := 0
		for i in n:
			if i >= line_idx - 60 and i <= idx_west + 60:
				continue
			if Vector2(r.baked[i].x - mid.x, r.baked[i].z - mid.z).length() < radius:
				cnt += 1
		print("  puncte de traseu strain sub %.0f m de mijloc: %d" % [radius, cnt])
	# Stațiile: prima la linia de oprire, apoi din STEP_M în STEP_M, ultima la
	# capătul de vest.
	var stations: Array[int] = []
	var d := 0.0
	var next_s := 0.0
	for k in range(line_idx, idx_west + 1):
		if k > line_idx:
			d += r.baked[r.wrap_index(k - 1)].distance_to(r.baked[r.wrap_index(k)])
		if d >= next_s or k == idx_west:
			stations.append(k)
			next_s += STEP_M
	print("")
	print("  --- teren fata de cota drumului (m; + = peste asfalt) ---")
	print("  %5s %6s | %6s %6s %6s %6s %6s %6s %6s" % ["m", "frac",
		"-15", "-10", "-6", "axa", "+6", "+10", "+15"])
	var terrain_in_tube := 0
	d = 0.0
	var dist_at: Dictionary = {}
	var prev := line_idx
	for k in stations:
		for j in range(prev + 1, k + 1):
			d += r.baked[r.wrap_index(j - 1)].distance_to(r.baked[r.wrap_index(j)])
		prev = k
		dist_at[k] = d
		var c: Vector3 = r.baked[r.wrap_index(k)]
		var s: Vector3 = r.side_at(r.wrap_index(k))
		var vals: Array[String] = []
		for off: float in [-15.0, -10.0, -6.0, 0.0, 6.0, 10.0, 15.0]:
			var p := c + s * off
			var ty := _terrain_top(space, p, terrain)
			if is_nan(ty):
				vals.append("   n/a")
			else:
				vals.append("%6.2f" % (ty - c.y))
				# Teren în volumul tubului: peste asfalt, sub tavan, între pereți.
				if absf(off) <= WIDTH_M * 0.5 and ty - c.y > 0.3 \
						and ty - c.y < CEILING_M:
					terrain_in_tube += 1
		var far: Array[String] = []
		for off: float in [-40.0, -30.0, -20.0, 20.0, 30.0, 40.0]:
			var ty := _terrain_top(space, c + s * off, terrain)
			far.append("n/a" if is_nan(ty) else "%.1f" % (ty - c.y))
		print("  %5.0f %6.3f | %s   @(%.1f, %.1f, %.1f)  departe -40/-30/-20/+20/+30/+40: %s" % [d, r.frac_at(r.wrap_index(k)), " ".join(vals), c.x, c.y, c.z, " ".join(far)])

	print("")
	print("  --- golul tubului (m) ---")
	print("  %5s | %6s %6s %6s | %6s | %s" % ["m", "stg", "dr", "latime",
		"tavan", "benzi (stg>=%.1f, dr>=%.1f sub %.1f m)" % [BUS_LEFT_M, CAR_RIGHT_M, LANE_TOP_M]])
	var tube_missing := 0
	var width_bad := 0
	var ceil_bad := 0
	var lane_bad := 0
	var min_w := INF
	var min_c := INF
	for k in stations:
		var c: Vector3 = r.baked[r.wrap_index(k)]
		var s: Vector3 = r.side_at(r.wrap_index(k))
		var min_l := INF
		var min_r := INF
		var lane_l := INF
		var lane_r := INF
		for h in WALL_HEIGHTS:
			var o := c + Vector3.UP * h
			var dl := _first_hit_dist(space, o, -s, SIDE_REACH, cars)
			var dr := _first_hit_dist(space, o, s, SIDE_REACH, cars)
			min_l = minf(min_l, dl)
			min_r = minf(min_r, dr)
			if h < LANE_TOP_M:
				lane_l = minf(lane_l, dl)
				lane_r = minf(lane_r, dr)
		var ceil_h := INF
		var off := -WIDTH_M * 0.5 + 0.1
		while off <= WIDTH_M * 0.5 - 0.1 + 0.001:
			var o := c + s * off + Vector3.UP * 0.3
			var up := _first_hit_dist(space, o, Vector3.UP, UP_REACH, cars)
			if up < INF:
				ceil_h = minf(ceil_h, up + 0.3)
			off += 0.4
		var has_tube := min_l < INF and min_r < INF and ceil_h < INF
		var w := min_l + min_r
		var flags: Array[String] = []
		if not has_tube:
			tube_missing += 1
			flags.append("FARA TUB")
		else:
			min_w = minf(min_w, w)
			min_c = minf(min_c, ceil_h)
			if w < WIDTH_M - TOL:
				width_bad += 1
				flags.append("INGUST")
			if ceil_h < CEILING_M - TOL:
				ceil_bad += 1
				flags.append("TAVAN JOS")
		if lane_l < BUS_LEFT_M - TOL or lane_r < CAR_RIGHT_M - TOL:
			lane_bad += 1
			flags.append("BANDA")
		print("  %5.0f | %6s %6s %6s | %6s | %s" % [dist_at[k],
			_fmt(min_l), _fmt(min_r), _fmt(w) if has_tube else "   n/a",
			_fmt(ceil_h), " ".join(flags) if not flags.is_empty() else "ok"])

	print("")
	print("  statii %d | fara tub %d | inguste %d | tavan jos %d | benzi %d | teren in tub %d"
		% [stations.size(), tube_missing, width_bad, ceil_bad, lane_bad, terrain_in_tube])
	if min_w < INF:
		print("  latime libera minima %.2f m (contract %.1f) | tavan minim %.2f m (contract %.1f)"
			% [min_w, WIDTH_M, min_c, CEILING_M])
	var ok := tube_missing == 0 and width_bad == 0 and ceil_bad == 0 \
		and lane_bad == 0 and terrain_in_tube == 0
	print("VERDICT TUNEL: %s" % ("OK" if ok else "PROBLEMA"))
	track.queue_free()
	await get_tree().process_frame
	return ok


func _fmt(v: float) -> String:
	return "   n/a" if v == INF else "%6.2f" % v


func _find_signal(node: Node) -> TunnelSignalHazard:
	if node is TunnelSignalHazard:
		return node as TunnelSignalHazard
	for c in node.get_children():
		var f := _find_signal(c)
		if f != null:
			return f
	return null


func _terrain_bodies(track: Track) -> Array[Node]:
	var out: Array[Node] = []
	for node in track.find_children("*", "StaticBody3D", true, false):
		if node.name.begins_with(TERRAIN_BODY):
			out.append(node)
	return out


## Fața de teren cea mai de sus deasupra (x, z), sau NAN dacă nu e teren.
func _terrain_top(space: PhysicsDirectSpaceState3D, p: Vector3,
		terrain: Array[Node]) -> float:
	var from := Vector3(p.x, p.y + 80.0, p.z)
	var to := Vector3(p.x, p.y - 40.0, p.z)
	var excl: Array[RID] = []
	for _pass in 12:
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = excl
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		if hit["collider"] in terrain:
			return float(hit["position"].y)
		excl.append(hit["rid"])
	return NAN


## Distanța până la primul corp lovit pe direcția dată, sau INF.
func _first_hit_dist(space: PhysicsDirectSpaceState3D, from: Vector3,
		dir: Vector3, reach: float, _ignore: Array[Node]) -> float:
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * reach)
	q.hit_back_faces = true
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return INF
	return from.distance_to(hit["position"])
