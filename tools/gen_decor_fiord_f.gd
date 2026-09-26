extends Node
## Generator de decor MANUAL pentru POI F — COBORAREA SI AVALANSA
## (Track16, Fiordland, frac 0.694-0.84, coborare 8% dupa iesirea din tunel).
##
## Ca gen_decor_mp_g.gd/gen_decor_ser_d.gd: nu e sonda, e unealta care CALCULEAZA
## transformarile ce se lipesc in Track16.tscn sub
## `DecorManual/ZoneF_Coborare`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordF.tscn -- \
##       --out=C:/cale/zoneF.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_fiordland/bara_poi_F.png)
##
## Drum in pante prin PADURE RARA, apoi cicatricea avalansei ca fasie GOALA
## de granit lucios cu trunchiuri si bolovani rostogoliti peste drum. Bara e
## LOOK, nu LAYOUT (docs/track_briefs/fiordland_poi_gauntlet.md): decizia (b)
## e ca fiordul NU e in fata aici (e in dreapta-spate, 87-138 grade) — nu se
## aduce.
##
## Capcana care decide POI-ul (memoria contrastul-nu-geometria): cicatricea se
## citeste prin CONTRAST DE CLASA (gneis lucios `wet_gneiss` fata de padure),
## nu prin numar de bolovani. `chasm_rock`/`moss_boulder_*` primesc deja
## `wet_gneiss`/`moss_carpet` pe tema fiordland (world_prop.gd
## CLASSES_BY_THEME/CLASSES_BY_MODEL) — generatorul doar le CONCENTREAZA pe
## cicatrice si le RAREste in padure, in loc sa le imprastie uniform.
##
## A DOUA capcana, de gameplay: avalansa (`AvalansaF`, marker la frac ~0.750)
## misca 9 bolovani PESTE drum intre 0.74 si 0.76 (plus 15 m lateral in ambele
## parti din memoria avalansa-alpii-ciclu-implicit + brief). Orice piesa cu
## coliziune in fasia aia BLOCHEAZA bolovanii (AnimatableBody3D-urile lor sunt
## corpuri fizice, nu fantome) — deci fasia ramane `none`/absenta.
##
## ------------------------------------------------------------------------
## SURVEY (runda 1, --survey) — cifrele care decid compozitia.

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneF_Coborare"

const F_IN := 0.694
const F_OUT := 0.840

## Avalansa: marker la ~0.750 (masurat pe .tscn), fasia mobila 0.74-0.76 +
## 15 m lateral pe ambele parti — ramane GOALA de coliziune (brief sectiunea F).
const AVALANCHE_FRAC := 0.750
const AVALANCHE_F_LO := 0.740
const AVALANCHE_F_HI := 0.760
const AVALANCHE_LAT_CLEAR := 15.0

## id-urile ext_resource din Track16.tscn (fundatia, deja inregistrate).
const RES := {
	"beech_a": "s_beech_a",
	"beech_b": "s_beech_b",
	"beech_c": "s_beech_c",
	"beech_dead": "s_beech_dead",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"chasm_rock": "s_chasm_rock",
	"guard_rock": "s_guard_rock",
	"driftwood": "s_driftwood",
	"tussock_clump": "s_tussock_clump",
}

## Inaltimea AABB masurata (docs/asset_briefs/fiordland_masuratori.md §1).
const HEIGHT := {
	"beech_a": 7.030, "beech_b": 10.189, "beech_c": 13.501,
	"beech_dead": 8.515,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"chasm_rock": 2.500,
	"guard_rock": 0.585,
	"driftwood": 0.384,
	"tussock_clump": 0.804,
}

## Raza de degajare la sol (m), scara 1: `beech_*` are coliziune `trunk`
## (raza masurata la baza); restul `hull` (jumatatea laturii mari a AABB).
const BASE_R := {
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03,
	"beech_dead": 0.68,
	"moss_boulder_a": 0.60, "moss_boulder_b": 1.10, "moss_boulder_c": 1.80,
	"chasm_rock": 3.02,
	"guard_rock": 0.59,
	"driftwood": 2.02,
	"tussock_clump": 0.35,
}

## Degajarea minima de la MUCHIA drumului la marginea corpului fizic, pentru
## orice piesa cu coliziune (AI-ul nu vede decor static — memoria
## obstacol-pe-drum-poate-fi-gimmick). `driftwood` explicit "trunchiuri cazute
## IN AFARA drumului" (brief F): degajare mai mare pentru el.
const EDGE_KEEP := 0.8
const EDGE_KEEP_DRIFTWOOD := 2.0

var _track: Track
var _sampler: TrackSideSampler
var _out: Array[String] = []
var _n := 0
var _skipped := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0
var _sun_to := Vector3(0.0, 1.0, 0.0)


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
	_rng.seed = 271601
	_survey()
	if not _survey_only:
		_scar()
		_scar_debris()
		_scar_pileup()
		_forest()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


func _survey() -> void:
	var sun := _find_sun(_track)
	var shadow := Vector3.ZERO
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		_sun_to = -dir
		shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, shadow.x, shadow.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        sol la -25 -15 -8 | +8 +15 +25   dot(side,umbra)")
	var f := F_IN - 0.005
	while f <= F_OUT + 0.005:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-25.0, -15.0, -8.0, 8.0, 15.0, 25.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_ground(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), s.dot(shadow)])
		f += 0.005


## Cota reala a terenului la (x,z): raycast pe TerrainBody, pornind de
## deasupra celui mai inalt punct al traseului (memoria terrain-mesh-y-extrapoleaza:
## _terrain_mesh_y extrapoleaza in afara panzei, nu se foloseste aici).
var _hi_y := -INF
func _ground(x: float, z: float) -> float:
	if _hi_y == -INF:
		for bp in _track.baked:
			_hi_y = maxf(_hi_y, bp.y)
		_hi_y += 150.0
	var space := _track.get_world_3d().direct_space_state
	var from := Vector3(x, _hi_y, z)
	var to := Vector3(x, _hi_y - 400.0, z)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = Track.CAMERA_BLOCKER_LAYER
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return -999.0
	return (hit.position as Vector3).y


# ------------------------------------------------------------------ compozitia

## Fractia e in fasia avalansei (+ marja laterala de siguranta AVALANCHE_LAT_CLEAR)?
func _in_avalanche_strip(f: float, lat: float) -> bool:
	if f < AVALANCHE_F_LO or f > AVALANCHE_F_HI:
		return false
	return absf(lat) <= AVALANCHE_LAT_CLEAR


## (1) CICATRICEA — fasie de granit lucios (`chasm_rock`/`moss_boulder_c`,
## clasa `wet_gneiss` deja aplicata pe tema) cu bolovani si `beech_dead`,
## SCREE_SLAB evitat ca grohotis principal (iese portocaliu-nisip pe tema
## asta — brief sectiunea F). Fasia mobila a avalansei ramane goala.
func _scar() -> void:
	var n := _track.baked.size()
	var f := AVALANCHE_F_LO - 0.010
	var f_end := AVALANCHE_F_HI + 0.010
	var idx := 0
	while f <= f_end:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		for sgn: float in [-1.0, 1.0]:
			# doua "randuri" laterale, la 9-13 si 16-22 m de ax
			for lat: float in [_jrange(9.0, 13.0), _jrange(16.0, 22.0)]:
				var lo := sgn * lat
				if _in_avalanche_strip(f, lo):
					continue # fasia mobila ramane goala (brief F)
				if absf(lo) < half + EDGE_KEEP:
					continue
				var q := p + s * lo
				var gy := _ground(q.x, q.z)
				if gy <= -900.0:
					continue
				var yaw := _rng.randf_range(0.0, TAU)
				var stems := ["chasm_rock", "moss_boulder_c", "moss_boulder_b", "guard_rock"]
				if _rng.randf() < 0.18:
					stems = ["beech_dead"]
				var stem: String = stems[_rng.randi() % stems.size()]
				_place(stem, q, gy, yaw, 1.0)
				idx += 1
		f += _step(3.2)
	print("; cicatrice: %d piese" % idx)


## (1b) MOLOZ IMEDIAT LANGA BANDA -- runda 2, verdict critic: langa bordura, in
## prim-plan-mijloc, unde referinta pune moloz angular + trunchiuri, noi aveam
## doar fasia goala (AVALANCHE_LAT_CLEAR) urmata de primul rand al _scar() la
## 9-13 m, prea departe pentru cadrul din masina. Aici pun un rand SUPLIMENTAR
## chiar la marginea benzii (15-19 m, adica AVALANCHE_LAT_CLEAR + 0-4 m) --
## tot in AFARA fasiei mobile (marja proprie, mai mare decat cea de siguranta
## normala) -- plus 2-3 trunchiuri rupte asezate OBLIC pe acostament
## (driftwood/beech_dead, tilt, NU pe carosabil). Bolovani angulari
## (chasm_rock/guard_rock -- gneis) NU moss_boulder rotund, ca sa nu repete
## defectul semnalat.
func _scar_debris() -> void:
	var n := _track.baked.size()
	var f := AVALANCHE_F_LO - 0.010
	var f_end := AVALANCHE_F_HI + 0.010
	var idx := 0
	var trunk_budget := 3 # 2-3 trunchiuri oblice, cerute explicit de critic
	while f <= f_end:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		for sgn: float in [-1.0, 1.0]:
			var lat := AVALANCHE_LAT_CLEAR + _jrange(0.6, 4.0)
			var lo := sgn * lat
			# marja proprie mai mare decat _in_avalanche_strip: raman departe
			# de fasia mobila (bucatile avalansei nu trebuie sa se blocheze).
			if absf(lo) <= AVALANCHE_LAT_CLEAR + 0.5:
				continue
			if absf(lo) < half + EDGE_KEEP:
				continue
			var q := p + s * lo
			var gy := _ground(q.x, q.z)
			if gy <= -900.0:
				continue
			var yaw := _rng.randf_range(0.0, TAU)
			# bolovani angulari, NU moss_boulder (rotund) - asta era defectul.
			var stems := ["chasm_rock", "chasm_rock", "guard_rock"]
			var stem: String = stems[_rng.randi() % stems.size()]
			_place(stem, q, gy, yaw, _rng.randf_range(0.9, 1.15))
			idx += 1
			# 2-3 trunchiuri oblice, rupte, peste marginea acostamentului --
			# axa lunga taind spre drum dar capatul interior oprit inainte de
			# asfalt (EDGE_KEEP normal: aici vrem "peste margine", nu departe).
			if trunk_budget > 0 and _rng.randf() < 0.5 and lat < AVALANCHE_LAT_CLEAR + 2.5:
				var stem_t: String = "driftwood" if _rng.randf() < 0.7 else "beech_dead"
				var tilt := _rng.randf_range(8.0, 22.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
				var yaw_t := yaw + deg_to_rad(_rng.randf_range(20.0, 55.0))
				_place(stem_t, q, gy, yaw_t, 1.0, tilt)
				trunk_budget -= 1
				idx += 1
		f += _step(2.4)
	print("; moloz langa banda (runda 2): %d piese, %d trunchiuri neplasate din buget" % [idx, trunk_budget])


## (1c) GRAMADA PESTE BANDA -- runda 3, verdict critic: r2 a lasat totul
## dincolo de AVALANCHE_LAT_CLEAR (15 m), deci NIMIC nu intersecta vizibil
## asfaltul (semi 7,0) si niciun trunchi nu ajungea pe marginea drumului --
## in bara, chiar in centrul cadrului, un trunchi masiv taie oblic PESTE
## marginea carosabilului si un morman de bolovani se suprapune pe asfalt,
## nu doar insirat paralel cu ea.
##
## Aici, spre deosebire de _scar_debris, intram DELIBERAT sub half+EDGE_KEEP:
## coliziune "none" pe fiecare piesa (AI-ul nu vede decor static -- memoria
## obstacol-pe-drum-poate-fi-gimmick -- si nota coordonatorului: intrarea pe
## asfalt e admisa DOAR fara coliziune). Doua grupuri (unul per parte a
## cicatricei), fiecare in AFARA fasiei mobile 0.740-0.760 -- limita ceruta
## EXPLICIT de coordonator (nu marja proprie de 0.008/0.010 din _scar/_scar_debris):
## inainte de 0.735 sau dupa 0.765, cat mai aproape de ea ca sa intre in cadrul
## de la 0.70/0.75/0.79.
##
## Trunchiul: driftwood (4,03 x 0,58 m) cu radacina pe acostament (~half+1,5)
## si varful trecand PESTE marginea asfaltului (~half-0,7), tilt mic (cade
## spre drum, nu se ridica). Bolovanii: guard_rock scalat mic (prag < 0,3 m
## inaltime -- memoria suprafete-cu-goluri-si-praguri, "prag nu zid") grupati
## in gramada (jitter mic intre ei, NU sir de-a lungul marginii -- ruperea
## alinierii ceruta explicit de coordonator), intrand pe asfalt intre
## ~half-2,0 si ~half+0,8.
## Runda 3c: un singur punct (0.734/0.766) s-a dovedit fragil -- drumul
## coteste chiar acolo (side vector se roteste de la (-0.65,+0.76) la
## (-0.40,+0.92) intre 0.719 si 0.734), deci care parte a cadrului "prinde"
## gramada depinde de UNDE se face captura, nu doar de cat de aproape e ea de
## fasie. In loc sa nimeresc un singur cadru, intind fiecare gramada pe o
## PLAJA de fractii (nu un punct), cu piese la fiecare pas -- ca ceva din ea
## sa fie mereu aproape de centrul drumului vazut din orice cadru rezonabil
## intre 0.70 si 0.79. Plajele raman strict in afara fasiei mobile (< 0.735,
## > 0.765 -- limita coordonatorului).
const PILEUP_RANGES := [[0.700, 0.734], [0.766, 0.800]]
const PILEUP_STEP := 0.003

func _scar_pileup() -> void:
	var n := _track.baked.size()
	var idx := 0
	for k in PILEUP_RANGES.size():
		var rng_f: Array = PILEUP_RANGES[k]
		var sgn: float = -1.0 if k == 0 else 1.0 # o gramada pe fiecare parte, in cadre diferite
		var f: float = rng_f[0]
		var f_end: float = rng_f[1]
		# densitate crescatoare spre fasie (aranjamentul-bate-numarul: nu
		# grila uniforma) -- piesele cele mai dese chiar la marginea permisa.
		while f <= f_end:
			if f > 0.735 and f < 0.765:
				push_warning("frac de gramada %.3f incalca limita 0.735/0.765, sarita" % f)
				f += PILEUP_STEP
				continue
			var i := int(f * float(n)) % n
			var p := _track.baked[i]
			var s := _track._side_at(i)
			var half := _track.width_at_index(i)

			# trunchi oblic la fiecare al doilea pas -- radacina pe acostament,
			# varful trecand ADANC peste banda (pana aproape de axa drumului,
			# half=7,0 -> varf la ~2,3 m de axa). Coliziune none: nu blocheaza
			# AI-ul, doar citeste vizual ca trunchi cazut peste carosabil.
			if _rng.randf() < 0.6:
				var root_lat := sgn * (half + 2.0)
				var tip_lat := sgn * (half - 4.7)
				var mid_lat := (root_lat + tip_lat) * 0.5
				var q_mid := p + s * mid_lat
				var gy_mid := _ground(q_mid.x, q_mid.z)
				if gy_mid > -900.0:
					var lat_dir := s * sgn
					var yaw := atan2(-lat_dir.z, lat_dir.x) + deg_to_rad(_rng.randf_range(-10.0, 10.0))
					var tilt := _rng.randf_range(4.0, 9.0)
					# scale uniform 1,8-2,1 (nu bulk_mul anizotrop -- runda 3f/3g
					# au incercat sa ingroase doar Y/Z si au deformat geometria
					# neregulata a modelului intr-un zig-zag urat). Un driftwood
					# mai mare in ansamblu tot citeste ca "trunchi masiv cazut",
					# lungimea mai mare (~7-8 m) fiind plauzibila pentru un fag
					# rupt de avalansa, nu doar o creanga.
					_place("driftwood", q_mid, gy_mid, yaw, _rng.randf_range(1.8, 2.1), tilt, "none")
					idx += 1

			# bolovani mari, angulari, la marginea asfaltului (half-1,0 pana
			# half+1,8) -- "mormanul" vizibil, coliziune none (sub EDGE_KEEP).
			for _rb in 2:
				var lat_b := sgn * _rng.randf_range(half - 1.0, half + 1.8)
				var qb := p + s * lat_b
				var gyb := _ground(qb.x, qb.z)
				if gyb <= -900.0:
					continue
				var yawb := _rng.randf_range(0.0, TAU)
				_place("chasm_rock", qb, gyb, yawb, _rng.randf_range(0.85, 1.1), 0.0, "none")
				idx += 1

			# pietre mici angulare care intra efectiv pe asfalt -- prag < 0,3 m
			# (memoria suprafete-cu-goluri-si-praguri), coliziune none.
			for _r in 2:
				var lat := sgn * _rng.randf_range(half - 3.2, half + 0.3)
				var q := p + s * lat
				var gy := _ground(q.x, q.z)
				if gy <= -900.0:
					continue
				var yaw := _rng.randf_range(0.0, TAU)
				var scl := _rng.randf_range(0.35, 0.50) # h masurata 0,585 -> 0,20-0,29 m
				_place("guard_rock", q, gy, yaw, scl, 0.0, "none")
				idx += 1
			f += PILEUP_STEP

		# CENTERPIECE, o singura data per grup, la capatul cel mai aproape de
		# fasie (unde captura de la 0,79/0,70 il vede aproape central): un
		# bolovan mare care intra ADANC pe banda (pana la half-3,0, adica
		# ~4 m de axa), nu doar pana la marginea ei -- criticul r3 cerea
		# explicit interesctie VIZIBILA cu asfaltul, nu doar bolovani langa
		# margine. Coliziune none (AI-ul nu vede decor static).
		var f_edge: float = rng_f[1] if k == 1 else rng_f[0]
		var i_edge := int(f_edge * float(n)) % n
		var p_edge := _track.baked[i_edge]
		var s_edge := _track._side_at(i_edge)
		var half_edge := _track.width_at_index(i_edge)
		var lat_edge := sgn * (half_edge - 3.0)
		var q_edge := p_edge + s_edge * lat_edge
		var gy_edge := _ground(q_edge.x, q_edge.z)
		if gy_edge > -900.0:
			_place("chasm_rock", q_edge, gy_edge, _rng.randf_range(0.0, TAU), 1.3, 0.0, "none")
			idx += 1
	print("; gramada peste banda (runda 3): %d piese (trunchiuri + bolovani mari + moloz mic pe asfalt)" % idx)


## Ranged jitter helper: numar random uniform in [a,b].
func _jrange(a: float, b: float) -> float:
	return _rng.randf_range(a, b)


## (2) PADUREA RARA — fagi rari (beech_a/b/c, coliziune trunk), tussock si
## driftwood ca trunchiuri cazute in AFARA drumului, pe restul feliei
## (0.694-0.84 minus cicatricea). Densitate scazuta ("rara" din decupaj) —
## aranjamentul bate numarul: jitter mare, yaw variat, fara grila (memoria
## aranjamentul-bate-numarul).
func _forest() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var idx := 0
	while f <= F_OUT:
		# in interiorul cicatricei (+ marja) nu punem padure — e fasia de granit
		if f >= AVALANCHE_F_LO - 0.010 and f <= AVALANCHE_F_HI + 0.010:
			f += _step(6.0)
			continue
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		for sgn: float in [-1.0, 1.0]:
			# "rara": nu la fiecare pas, si nu pe fiecare parte
			if _rng.randf() < 0.45:
				continue
			var lat := half + EDGE_KEEP + _jrange(1.5, 14.0)
			var q := p + s * (sgn * lat)
			var gy := _ground(q.x, q.z)
			if gy <= -900.0:
				continue
			var yaw := _rng.randf_range(0.0, TAU)
			var roll := _rng.randf()
			if roll < 0.55:
				var stem: String = ["beech_a", "beech_b", "beech_c"][_rng.randi() % 3]
				_place(stem, q, gy, yaw, 1.0)
				idx += 1
			elif roll < 0.75:
				_place("tussock_clump", q, gy, yaw, _rng.randf_range(0.8, 1.3))
				idx += 1
			elif roll < 0.90:
				# driftwood: trunchi cazut, explicit IN AFARA drumului -> degajare mai mare
				if absf(lat) < EDGE_KEEP_DRIFTWOOD:
					continue
				_place("driftwood", q, gy, yaw, 1.0)
				idx += 1
			else:
				_place("guard_rock", q, gy, yaw, _rng.randf_range(0.9, 1.2))
				idx += 1
		f += _step(4.5)
	print("; padure rara: %d piese" % idx)


## Pas in FRACTIE echivalent unei distante `meters` pe traseu, cu jitter
## >= 0.5 din pas (memoria aranjamentul-bate-numarul: fara grila).
func _step(meters: float) -> float:
	var base := meters / _total_len
	return base * _rng.randf_range(0.55, 1.55)


## Aseaza o piesa: verifica degajarea de la muchia drumului daca are coliziune,
## scrie linia .part. `gy` e cota REALA din raycast (TerrainBody), nu campul
## neted (memoria terrain-mesh-y-extrapoleaza).
## `tilt_deg`: pentru trunchiuri "cazute oblic" — o rotatie SUPLIMENTARA pe
## axa locala Z (PERPENDICULARA pe lungimea trunchiului, care e X local la
## `driftwood`: baza masurata 4,03 x 0,58 m), aplicata INAINTE de yaw, deci
## trunchiul se inclina (un capat mai jos) fara sa se roteasca in jurul
## propriei axe lungi. 0 = fara tilt (default, neschimbat pentru restul
## pieselor). Runda 3: fixat -- tiltul era pe Vector3.RIGHT (chiar axa lunga),
## deci trunchiul se rula pe loc in loc sa cada oblic (vizibil in captura:
## trunchiul aparea vertical/subtire, nu culcat peste asfalt).
func _place(stem: String, pos: Vector3, ground_y: float, yaw: float, scale_mul: float, tilt_deg: float = 0.0, coliziune_mode: String = "", bulk_mul: float = 1.0) -> void:
	if not RES.has(stem):
		_skipped += 1
		return
	var h: float = HEIGHT.get(stem, 1.0)
	var scale := scale_mul # inaltimea e deja cea masurata; scale_mul e variatie, nu conversie in metri
	var basis := Basis(Vector3.UP, yaw)
	if tilt_deg != 0.0:
		# tilt pe axa locala Z (perpendiculara pe lungimea X), apoi yaw peste.
		basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, deg_to_rad(tilt_deg))
	basis = basis.scaled(Vector3.ONE * scale)
	if bulk_mul != 1.0:
		# ingroasa modelul pe Y si Z locale (grosimea), pastrand lungimea X --
		# un driftwood standard (4,03 x 0,58) citea prea subtire/greu de vazut
		# ca "trunchi masiv" din unghiul de sus-spate al camerei de joc.
		basis.y *= bulk_mul
		basis.z *= bulk_mul
	var origin := Vector3(pos.x, ground_y, pos.z)
	_n += 1
	var name := "%s%d" % [_camel(stem), _n]
	_out.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [name, ZONE, RES[stem]])
	_out.append("transform = Transform3D(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % [
		_f(basis.x.x), _f(basis.y.x), _f(basis.z.x),
		_f(basis.x.y), _f(basis.y.y), _f(basis.z.y),
		_f(basis.x.z), _f(basis.y.z), _f(basis.z.z),
		_f(origin.x), _f(origin.y), _f(origin.z)])
	if not coliziune_mode.is_empty():
		# suprascrie modul implicit al piesei (metadata `coliziune`, citita in
		# world_prop.gd COLLISION_META) -- folosit pentru piese care intra
		# deliberat pe asfalt (gramada de la avalansa) si NU trebuie sa
		# blocheze AI-ul sau bucatile de avalansa.
		_out.append('metadata/coliziune = "%s"' % coliziune_mode)
	_out.append("")


func _camel(stem: String) -> String:
	var parts := stem.split("_")
	var s := parts[0]
	for k in range(1, parts.size()):
		s += parts[k].capitalize()
	return s


func _f(v: float) -> String:
	return "%.4f" % v


func _write() -> void:
	if _out_path.is_empty():
		print("; --out lipseste, nu scriu nimic (%d piese calculate)" % _n)
		return
	var f := FileAccess.open(_out_path, FileAccess.WRITE)
	for line in _out:
		f.store_line(line)
	f.close()
	print("; scris %s: %d noduri, %d sarite (lipsa in RES)" % [_out_path, _n, _skipped])
