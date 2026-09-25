extends Node
## Generator de decor MANUAL pentru POI G — KICKERUL BOWEN (Track16,
## Fiordland, frac 0.84-0.90, `DecorManual/ZoneG_Bowen`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordG.tscn -- \
##       --out=C:/cale/zoneG.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, cota rapei) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (bara_poi_G.png)
##
## Cascada inalta in perete PE DREAPTA, bazin de apa alba cu spray la baza,
## kicker de piatra, masina IN spray, pietris la aterizare, padure pe
## AMANDOUA malurile. Bara e LOOK, nu LAYOUT: se compara materia (stanca uda,
## spuma, pietrisul, padurea), nu unde cade fiecare obiect.
##
## ------------------------------------------------------------------------
## CONTRACT (fiordland_poi_gauntlet.md §G)
##
## Rapa Bowen e indexul 2 din custom_ravines: Vector4(0.84, 0.902, 6, -1) —
## fund -8, latime efectiva 22, side -1 (semnul lui _side_at() — se verifica
## la survey, nu se presupune, memoria rotatii-in-builder-semnul). NU e
## cornice si NU e scarp (doar indicii 0 si 3 sunt cornice) — cade in panta,
## nu in prag vertical.
##
## `KickerBowen` (TrackChannel, Hazarduri) e la lumea (91.0, 0.2, -67.5),
## gap=12, water_half=6, bank=6, depth=7 — saltul e REGLAT: nicio piesa cu
## coliziune pe traiectoria de zbor sau pe aterizare (frac 0.85-0.875, la
## +-7 m de ax). Perdeaua Bowen insasi (WaterfallVisual) NU e in scena inca
## (doar 6 din cele 7 arii de cascada exista azi: B1/B2/Chasm/F1/F2/Stirling
## — Bowen o adauga fundatia separat); POI-ul G construieste DOAR ce e in
## jur: peretele din care ar cadea (bolovani mari `moss_boulder`, `chasm_rock`
## in bazin, `guard_rock`), pietrisul aterizarii (clasa SAND_SHADOW pe teren,
## nu GLB), spuma bazinului (`FOAM_WHITE`, PaletteBox), padurea pe maluri
## (fagii — coronamentul in placi e decizie de asset deschisa, nu se repara
## aici), driftwood la apa.
##
## Piese: `beech_a/b/c` (trunk), `beech_dead`, `moss_boulder_a/b/c` (reuse MP,
## clasa moss_carpet), `fern_cluster`, `tree_fern` (reuse MP), `guard_rock`,
## `tussock_clump`, `chasm_rock`, `driftwood`.
##
## Capcana: memoria ProbeRace la 0.858 — saltul e reglat (gap 12). Orice piesa
## cu coliziune pe 0.85-0.875 (+-7 m de ax) schimba distributia de repuneri —
## ProbeRace --slice=0.83,0.90 obligatoriu, seed 1/2, uscat SI ploaie,
## comparat cu starea de plecare (exista un [blocaj] intermitent cunoscut la
## 0.876-0.892 PE MAIN, se masoara inainte de decor). Peretele cascadei e
## TEREN (horizon_class / rapa) — daca citeste plat, e clasa de textura, nu
## decor (regula c).

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneG_Bowen"

const F_IN := 0.840
const F_OUT := 0.902

## id-urile ext_resource deja inregistrate in Track16.tscn.
const RES := {
	"beech_a": "s_beech_a",
	"beech_b": "s_beech_b",
	"beech_c": "s_beech_c",
	"beech_dead": "s_beech_dead",
	"tussock_clump": "s_tussock_clump",
	"guard_rock": "s_guard_rock",
	"fern_cluster": "s_fern_cluster",
	"tree_fern": "s_tree_fern",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"chasm_rock": "s_chasm_rock",
	"driftwood": "s_driftwood",
}

## Inaltimea AABB masurata (docs/asset_briefs/fiordland_masuratori.md §1).
const HEIGHT := {
	"beech_a": 7.030, "beech_b": 10.189, "beech_c": 13.501, "beech_dead": 8.515,
	"tussock_clump": 0.804, "guard_rock": 0.585,
	"fern_cluster": 1.2, "tree_fern": 3.306,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"chasm_rock": 2.500, "driftwood": 0.384,
}

## Raza de DEGAJARE la sol (m) la scara 1: raza corpului fizic.
## Fagii au coliziune `trunk` (cilindru in ax) — raza la baza masurata.
const BASE_R := {
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03, "beech_dead": 0.68,
	"tussock_clump": 0.05, "guard_rock": 0.65,
	"fern_cluster": 0.35, "tree_fern": 0.54,
	"moss_boulder_a": 0.741 * 0.5, "moss_boulder_b": 1.957 * 0.5, "moss_boulder_c": 3.069 * 0.5,
	"chasm_rock": 3.02, "driftwood": 2.00,
}

const TRI := {
	"beech_a": 228, "beech_b": 292, "beech_c": 292, "beech_dead": 136,
	"tussock_clump": 144, "guard_rock": 72,
	"fern_cluster": 200, "tree_fern": 768,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"chasm_rock": 416, "driftwood": 52,
}

## Coliziune per piesa (world_prop.gd o suprascrie oricum dupa nume, dar
## generatorul scrie explicit metadata pentru cele care NU sunt hull implicit).
const COLLISION := {
	"beech_a": "trunk", "beech_b": "trunk", "beech_c": "trunk", "beech_dead": "trunk",
	"tussock_clump": "none", "fern_cluster": "none", "tree_fern": "hull",
	"guard_rock": "hull",
	"moss_boulder_a": "hull", "moss_boulder_b": "hull", "moss_boulder_c": "hull",
	"chasm_rock": "hull", "driftwood": "none",
}

## Degajarea minima de la MUCHIA drumului la marginea corpului fizic, pentru
## orice piesa cu coliziune.
const EDGE_KEEP := 0.8
const NEAR_WINDOW_FRAC := 0.012
const OTHER_ROAD_KEEP := 1.2
## probe_manual numara "IN DRUM" orice punct sub semi-latime + 2,0 m (memoria
## garda-fara-linie-de-baza-iese-zero). ROAD_MARGIN aici e RIDICAT peste
## garda de baza (2,0) tocmai pe felia saltului (vezi JUMP_BAND), ca sa nu
## fie nevoie sa ne apropiem de traiectorie ca sa trecem proba.
const ROAD_MARGIN := 2.1

## FELIA SALTULUI — kickerul e REGLAT (gap 12). Nicio piesa cu coliziune pe
## 0.85-0.875 la mai putin de 7 m de ax (contract explicit). Se tine 0.848-
## 0.877 si 8.0 m ca marja de siguranta peste cifra din contract.
##
## RUNDA 1, PRIMA TRECERE (ProbeRace seed 1/2 --slice=0.83,0.90): [blocaj]
## repetat la frac 0.872-0.881, lat 5.8-7.9, atingand poolWall39/poolWall51 —
## AMANDOUA in afara benzii declarate mai sus (0.848-0.877), pe ATERIZAREA
## dupa kicker, unde masinile care aluneca lateral dupa salt ajung mai departe
## de ax decat pe traiectoria de zbor insasi. Banda de siguranta trebuia sa
## acopere si aterizarea propriu-zisa, nu doar zborul. Extinsa la 0.848-0.888
## (contract 0.85-0.875 + marja) si JUMP_LAT la 9.5 m (masurat: blocajul cel
## mai indepartat a fost la 7.9 m, deci 9.5 lasa 1.6 m rezerva).
const JUMP_F_LO := 0.848
const JUMP_F_HI := 0.888
const JUMP_LAT := 9.5

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _skipped := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0
var _wall_sign := -1.0   # semnul lui _side_at() pe care cade peretele cascadei (survey)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 170926
	_survey()
	if not _survey_only:
		_pool_wall()
		_landing_gravel()
		_foam_pool()
		_bank_forest()
		_driftwood_banks()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        sol la -3 -6 -9 -15 -25 -40 | +3 +6 +9 +15 +25 +40   sgn_perete")
	var f := F_IN - 0.01
	while f <= F_OUT + 0.01:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -9.0, -6.0, -3.0, 3.0, 6.0, 9.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		# peretele (cascada) e pe partea unde caderea e cea mai mare la 25/40 m
		# (contract: side -1 al rapei, dreapta la decupaj — se verifica, nu se
		# presupune).
		var d_neg := _sol_real((p + s * -25.0).x, (p + s * -25.0).z) - p.y
		var d_pos := _sol_real((p + s * 25.0).x, (p + s * 25.0).z) - p.y
		var sgn_perete := -1.0 if d_neg < d_pos else 1.0
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.0f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), sgn_perete])
		f += 0.004
	# semnul dominant pe toata felia
	var votes := 0
	var f2 := F_IN
	while f2 <= F_OUT:
		var i2 := int(f2 * float(n)) % n
		var p2 := _track.baked[i2]
		var s2 := _track._side_at(i2)
		var dn := _sol_real((p2 + s2 * -25.0).x, (p2 + s2 * -25.0).z) - p2.y
		var dp := _sol_real((p2 + s2 * 25.0).x, (p2 + s2 * 25.0).z) - p2.y
		votes += (1 if dn < dp else -1)
		f2 += 0.01
	_wall_sign = -1.0 if votes > 0 else 1.0
	print("; sgn_perete dominant = %+.0f (votes=%d)" % [_wall_sign, votes])
	# cota kicker-ului (KickerBowen, TrackChannel) pentru context.
	print("; KickerBowen la lumea (91.0, 0.2, -67.5), gap=12 water_half=6 bank=6 depth=7")


## Normala suprafetei din raycast REAL pe TerrainBody.
func _normal_real(x: float, z: float) -> Vector3:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	if _terrain_rid == RID():
		return Vector3.UP
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = []
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _terrain_rid:
		return (hit["normal"] as Vector3)
	return Vector3.UP


# ------------------------------------------------------------------ compozitia

## (1) PERETELE / BAZINUL CASCADEI — pe partea `_wall_sign`, bolovani mari
## (moss_boulder_b/c, chasm_rock) langa perete si in bazin, guard_rock la
## marginea drumului. Pas mic, jitter, densitate crescanda spre kicker
## (0.858) — aranjamentul-bate-numarul.
func _pool_wall() -> void:
	var n := _track.baked.size()
	var side_sign := _wall_sign
	var placed := 0
	var skipped := 0
	var f := F_IN + 0.003
	while f < F_OUT - 0.003:
		var center_dist := absf(f - 0.858)
		var density := clampf(1.0 - center_dist / 0.03, 0.35, 1.0)
		var cluster := 1 + (1 if _rng.randf() < density else 0)
		for k in cluster:
			if _rng.randf() < (0.6 + 0.35 * density):
				var i := int(f * float(n)) % n
				var p: Vector3 = _track.baked[i]
				var s: Vector3 = _track._side_at(i) * side_sign
				var half: float = _track.width_at_index(i)
				var model: String = ["chasm_rock", "moss_boulder_b", "moss_boulder_c", "chasm_rock", "guard_rock"][_rng.randi_range(0, 4)]
				# scl ALES INAINTE de calculul marginii — RUNDA 1, A DOUA
				# TRECERE: pragul de siguranta al saltului folosea raza
				# NESCALATA (BASE_R), dar piesa se aseaza cu `scl` pana la 1.5x
				# aplicat DUPA. Masurat pe blocaj: poolWall46 (guard_rock,
				# scl masurat 1.269 din transform) avea muchia reala la
				# 9.5*0.65/... de fapt centrul calculat pe raza nescalata, deci
				# muchia REALA (scalata) ateriza cu ~0.3*r inauntrul pragului —
				# exact [blocaj] repetat la frac 0.878 lat 7.9-7.9, identic la
				# fiecare rulare (Tu (Muscle) t=66.0/69.0s, seed 2, 2 rulari).
				# Fix: raza foloseste `r * scl` peste tot unde intra in geometria
				# de asezare, nu doar raza de baza.
				var scl: float = _rng.randf_range(1.0, 1.5)
				var r: float = BASE_R.get(model, 0.9) * scl
				var gap := _rng.randf_range(1.0, 4.5) + float(k) * 1.6
				# banda saltului: MUCHIA (nu centrul) piesei trebuie sa ramana
				# la >= JUMP_LAT m de ax pe 0.848-0.888 (contract explicit).
				if f >= JUMP_F_LO and f <= JUMP_F_HI:
					gap = maxf(gap, JUMP_LAT - half + 0.3)
				var d := half + gap + r
				var q := p + s * d
				var nrm := _normal_real(q.x, q.z)
				var g := _sol_real(q.x, q.z)
				var analytic := _sampler.ground_y(q.x, q.z)
				# Acelasi prag ca la POI B (CLIFF_DELTA_MAX): peste 1.8 m
				# raycast-ul si campul neted diverg (memoria
				# terrain-mesh-y-extrapoleaza) — probe_manual verifica fata de
				# campul neted, deci o piesa asezata pe raycast in banda de
				# divergenta iese INGROPAT/PLUTESTE la proba, desi vizual sta
				# corect pe panta reala. Se sare, nu se forteaza.
				if absf(g - analytic) > 1.8:
					skipped += 1
					continue
				if d - r < half + EDGE_KEEP:
					skipped += 1
					continue
				var yaw := _rng.randf_range(0.0, TAU)
				_raw(model, "poolWall", Vector3(q.x, g, q.z), yaw, scl, "hull")
				placed += 1
				# muschi/ferigi ca accent pe bolovani, aproape de apa.
				if _rng.randf() < 0.4:
					var moss_model: String = "fern_cluster" if _rng.randi_range(0, 1) == 0 else "tussock_clump"
					var moss_gap := gap + r * 1.2 + _rng.randf_range(-0.3, 0.3)
					var qm := p + s * (half + moss_gap)
					var gm := _sol_real(qm.x, qm.z)
					_raw(moss_model, "poolMoss", Vector3(qm.x, gm, qm.z),
						_rng.randf_range(0.0, TAU), _rng.randf_range(0.6, 0.95), "none")
		f += _step(_rng.randf_range(2.0, 3.6))
	print("; perete/bazin cascada: %d piese (chasm_rock/moss_boulder/guard_rock), %d sarite" % [placed, skipped])


## (2) PIETRISUL ATERIZARII — clasa de teren (SAND_SHADOW), NU GLB. Aici doar
## marcheaza vizual cu cateva pietre mici (guard_rock) langa banda de
## aterizare, in AFARA benzii saltului (0.85-0.875, +-7 m). world_prop.gd nu
## ofera o "clasa" direct din generator — asta ramane treaba fundatiei
## (custom_step_ranges/texturi de sol); aici punem doar accent 3D discret,
## la distanta sigura de aterizare.
func _landing_gravel() -> void:
	var n := _track.baked.size()
	var side_sign := -_wall_sign  # malul opus peretelui, unde aterizeaza masina
	var placed := 0
	var fracs: Array[float] = [0.878, 0.882, 0.887, 0.893]
	for f in fracs:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i) * side_sign
		var half: float = _track.width_at_index(i)
		var gap := _rng.randf_range(3.0, 6.0)
		var d := half + gap
		var q := p + s * d
		var g := _sol_real(q.x, q.z)
		_raw("guard_rock", "gravelEdge", Vector3(q.x, g, q.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.7, 1.0), "hull")
		placed += 1
	print("; pietris aterizare: %d pietre de accent la marginea benzii" % [placed])


## (3) SPUMA BAZINULUI — FOAM_WHITE (PaletteBox, prin `FoamPoolG`, acelasi
## tipar ca `FoamPool` de la POI C, neintegrat inca pe aceasta ramura — brief-ul
## §G permite explicit PaletteBox FOAM_WHITE direct). Grupuri de spuma langa
## baza peretelui, pe partea `_wall_sign`, concentrate spre 0.858 (kicker).
const FOAM_RES_ID := "10_foam_pool_g"

func _foam_pool() -> void:
	var n := _track.baked.size()
	var side_sign := _wall_sign
	var placed := 0
	var fracs: Array[float] = [0.850, 0.854, 0.858, 0.862, 0.866]
	var seed0 := 170930
	for f in fracs:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i) * side_sign
		var half: float = _track.width_at_index(i)
		var gap := _rng.randf_range(2.0, 4.0)
		var d := half + gap
		var q := p + s * d
		var g := _sol_real(q.x, q.z)
		_n += 1
		var node_name := "foamPoolG%d" % _n
		_out.append('[node name="%s" type="Node3D" parent="%s"]' % [node_name, ZONE])
		_out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)'
			% [q.x, g, q.z])
		_out.append('script = ExtResource("%s")' % FOAM_RES_ID)
		_out.append('patch_count = 9')
		_out.append('radius = %f' % _rng.randf_range(1.6, 2.4))
		_out.append('rng_seed = %d' % (seed0 + _n))
		_out.append("")
		placed += 1
	print("; spuma bazin: %d grupuri FOAM_WHITE (FoamPoolG) langa baza peretelui" % [placed])


## (4) PADUREA PE MALURI — fagi rari (brief: nu perdea densa ca la POI D),
## pe AMBELE maluri (peretele cascadei SI malul opus). Densitate moderata,
## suprapunere de coroane ca sa nu ramana ferestre de iarba (aranjamentul-
## bate-numarul), dar mult mai rara decat POI D.
##
## RUNDA 2, verdict critic: malul de la 40-65% din latimea cadrului, "intre
## bolovanii din prim-plan si cotul drumului", citea "gard/aliniament".
## Verificat pe captura marcata cu linii la 40%/65%: fasia respectiva cade
## PESTE bolovanii+fagii de la peretele cascadei (poolWall/bankForest82-93,
## side_sign == _wall_sign), NU peste malul opus — desi "peretele" e in
## dreapta geografica dupa contract, la unghiul de camera al POI-ului G
## (curba + chase cam) el proiecteaza in stanga cadrului. Fix aplicat pe
## side_sign == _wall_sign: gap si pasul de-a lungul drumului devin PER
## INSTANTA (jitter >= 0,5 din pas in ambele axe), 2-3 randuri de adancime cu
## offset-uri care se suprapun (nu benzi separate cu goluri intre ele), plus
## clustere dense intercalate cu goluri explicite. Malul opus (-_wall_sign,
## aterizarea) ramane pe reteta veche (nu a fost numit de critic).
func _bank_forest() -> void:
	var n := _track.baked.size()
	for side_sign: float in [_wall_sign, -_wall_sign]:
		var jittered: bool = side_sign == _wall_sign
		if not jittered:
			var bands: Array[Vector2] = [Vector2(9.0, 14.0), Vector2(14.0, 20.0)]
			for band_i in bands.size():
				var band: Vector2 = bands[band_i]
				var f := F_IN + 0.006 + float(band_i) * 0.003
				while f < F_OUT - 0.006:
					if _rng.randf() < 0.6:
						var model: String = ["beech_a", "beech_a", "beech_b", "beech_c", "beech_dead"][_rng.randi_range(0, 4)]
						var gap: float = _rng.randf_range(band.x, band.y)
						var scl := _rng.randf_range(0.9, 1.1)
						_place(model, "bankForest", f, side_sign, gap,
							_rng.randf_range(0.0, TAU), scl, "trunk")
					f += _step(_rng.randf_range(3.5, 6.0))
		else:
			# malul stang: 2-3 randuri de adancime, gap si pas jitterate per
			# instanta (>= 0,5 din pas), clustere dense + goluri intercalate,
			# in loc de benzi paralele cu gap fix.
			var depth_bands: Array[Vector2] = [Vector2(8.0, 13.0), Vector2(12.0, 18.0), Vector2(17.0, 24.0)]
			for band_i in depth_bands.size():
				var band: Vector2 = depth_bands[band_i]
				var base_step := 4.5
				var f := F_IN + 0.004 + float(band_i) * 0.0025
				# faza de cluster/gol independenta per rand, ca randurile sa nu
				# se goleasca in acelasi punct de-a lungul drumului.
				var cluster_phase := _rng.randf_range(0.0, TAU)
				while f < F_OUT - 0.004:
					if f >= JUMP_F_LO and f <= JUMP_F_HI:
						# fereastra saltului: copacii raman departe de banda,
						# dar tot cu jitter (nu revenim la pas fix).
						f += _step(base_step * _rng.randf_range(0.7, 1.4))
						continue
					# densitate variabila de-a lungul drumului: clustere (pana
					# la 2 trunchiuri apropiate) alternand cu goluri, in loc de
					# o proba uniforma per pozitie.
					var cluster_wave: float = sin(cluster_phase + f * 220.0)
					var p_place: float = clampf(0.72 + 0.28 * cluster_wave, 0.15, 0.95)
					if _rng.randf() < p_place:
						var model: String = ["beech_a", "beech_a", "beech_b", "beech_c", "beech_dead"][_rng.randi_range(0, 4)]
						var gap: float = _rng.randf_range(band.x, band.y)
						var scl := _rng.randf_range(0.85, 1.15)
						var f_here := f + _step(_rng.randf_range(-1.8, 1.8))
						_place(model, "bankForest", f_here, side_sign, gap,
							_rng.randf_range(0.0, TAU), scl, "trunk")
						# cluster ocazional: al doilea trunchi aproape, adancime
						# si pozitie proprii, ca sa rupa ritmul de rand unic.
						if cluster_wave > 0.5 and _rng.randf() < 0.45:
							var model_c: String = ["beech_a", "beech_b", "beech_c"][_rng.randi_range(0, 2)]
							var gap_c: float = clampf(gap + _rng.randf_range(-3.0, 3.5), band.x - 2.0, band.y + 4.0)
							var f_c := f_here + _step(_rng.randf_range(1.0, 3.0))
							_place(model_c, "bankForest", f_c, side_sign, gap_c,
								_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.15), "trunk")
					# pasul de-a lungul drumului variaza puternic (jitter >=
					# 0,5 din pasul de baza) in loc de un increment ingust.
					f += _step(base_step * _rng.randf_range(0.5, 1.9))
		# vegetatie joasa la baza trunchiurilor + cate un tree_fern rar.
		var f2 := F_IN
		while f2 < F_OUT:
			if _rng.randf() < 0.5:
				var model2: String = ["fern_cluster", "tussock_clump", "fern_cluster", "tree_fern"][_rng.randi_range(0, 3)]
				var gap2 := _rng.randf_range(4.0, 8.5)
				_place(model2, "bankUnder", f2, side_sign, gap2,
					_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.2), COLLISION.get(model2, "hull"))
			f2 += _step(_rng.randf_range(2.5, 4.5))


## (5) DRIFTWOOD LA APA — cateva trunchiuri cazute langa bazin, pe malul
## peretelui, aproape de apa (brief: "driftwood la apa").
func _driftwood_banks() -> void:
	var n := _track.baked.size()
	var fracs: Array[float] = [0.845, 0.862, 0.878, 0.895]
	var placed := 0
	for f in fracs:
		var side_sign: float = _wall_sign if _rng.randf() < 0.6 else -_wall_sign
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i) * side_sign
		var half: float = _track.width_at_index(i)
		var gap := _rng.randf_range(2.5, 5.5)
		var d := half + gap
		var q := p + s * d
		var g := _sol_real(q.x, q.z)
		_raw("driftwood", "poolDrift", Vector3(q.x, g, q.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.9, 1.2), "none")
		placed += 1
	print("; driftwood: %d trunchiuri langa bazin" % [placed])


func _step(meters: float) -> float:
	return meters / _total_len


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la MARGINEA corpului fizic. Cota din raycast pe TerrainBody.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull") -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	gap = maxf(gap, ROAD_MARGIN - r)
	# felia saltului: MUCHIA piesei (d - r) trebuie sa ramana la >= JUMP_LAT
	# (acelasi fix ca in _pool_wall — gap se calculeaza pentru muchie, nu
	# pentru centru).
	if frac >= JUMP_F_LO and frac <= JUMP_F_HI and mode != "none":
		gap = maxf(gap, JUMP_LAT - half + 0.3)
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	if mode != "none" and _on_any_road(q, i, r):
		_skipped += 1
		return
	var smooth := _sampler.ground_y(q.x, q.z)
	var sink := smooth - g
	var piece_h: float = float(HEIGHT.get(model, 1.0)) * scl
	var zvelt: bool = model.begins_with("beech")
	var max_sink: float = 0.8 if zvelt else maxf(0.5 * piece_h, 1.0)
	if sink > max_sink:
		_skipped += 1
		return
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode)


func _on_any_road(p: Vector3, home_i: int, body_r: float) -> bool:
	var n := _track.baked.size()
	var skip := int(round(float(n) * NEAR_WINDOW_FRAC))
	for i in n:
		var di := absi(i - home_i)
		di = mini(di, n - di)
		if di <= skip:
			continue
		var b: Vector3 = _track.baked[i]
		var dx := b.x - p.x
		var dz := b.z - p.z
		var clear: float = _track.width_at_index(i) + OTHER_ROAD_KEEP + body_r
		if dx * dx + dz * dz < clear * clear:
			return true
	return false


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri).
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate (cota/margine), %d avertismente, ~%d triunghiuri" % [_n, _skipped, _warn, _tri])
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody), nu din
## campul neted si nu din _terrain_mesh_y (memoria terrain-mesh-y-extrapoleaza).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)
