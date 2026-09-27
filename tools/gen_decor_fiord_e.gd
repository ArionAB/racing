extends Node
## Generator de decor MANUAL pentru POI E — URCAREA SI PORTALUL DE EST
## (Track16, Fiordland, frac 0.46-0.612, urcare 12% pe drum taiat in
## grohotis, pana la portalul tunelului Homer).
##
## Ca la Machu Picchu POI G (gen_decor_mp_g.gd): nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track16.tscn sub
## `DecorManual/ZoneE_Portal`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordE.tscn -- \
##       --out=C:/cale/zoneE.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_fiordland/bara_poi_E.png)
##
## Gura de beton cu galeria de avalansa (arcade) si semaforul pe stalp,
## masivul de granit gol deasupra, grohotis pe panta, chevron-uri pe urcare,
## padurea se rareste spre portal, autocarul in gura. Bara e LOOK, nu LAYOUT
## (docs/track_briefs/fiordland_poi_gauntlet.md): se compara MATERIA — beton
## ud, grohotis, rarirea padurii — nu unde cade fiecare obiect. Galeria cu
## arcade NU e in kit (portalurile sunt COD, Track._build_tunnels) — POI-ul E
## NU construieste tunelul, doar decorul din jurul lui.
##
## ------------------------------------------------------------------------
## CONTRACTUL RUNDEI 1 (fiordland_poi_gauntlet.md, sectiunea E):
##
## 1. [ISTORIC — STALPUL DE SEMAFOR A FOST ELIMINAT, decizia dezvoltatorului,
##    sep 2026.] Runda 1 cerea `trafficPoleEast` pastrat ca fundatie la splice,
##    cu `HazardLamp` mutat in alveolele lui. In joc lampile ramaneau ingropate
##    in movila tunelului si nu se vedeau (`docs/track_briefs/fiordland_stare_poi.md`
##    decizia deschisa #7) — stalpul (`traffic_light_pole.glb`) si `Lampa`-i
##    copil au fost scosi din `DecorManual/ZoneE_Portal` in Track16.tscn.
##    `SemaforTunel.lamp` a ramas `NodePath("Lampa")` — un nume relativ care nu
##    mai gaseste nimic sub stalp (nu mai exista), deci `TunnelSignalHazard._ready()`
##    (`if lamp == null: lamp = HazardLamp.new(); ... add_child(lamp)`) construieste
##    singur un `HazardLamp` implicit ca fiu direct al `SemaforTunel`, pe pozitia
##    LUI (nu a stalpului) — exact comportamentul dinainte de runda 1. Niciun
##    NodePath ramas mort: `lamp` se rezolva mereu, fie la un nod real, fie la
##    null care declanseaza fallback-ul. Acest generator nu construieste
##    stalpul si nu-l mai mentioneaza in output — orice piesa noua din ZoneE
##    ramane libera sa foloseasca spatiul unde statea el.
## 2. CULOARUL AUTOCARULUI: nimic cu coliziune pe cei 9 m ai gurii (semilatime
##    tunel 4,5) si pe aripile-palnie (cod). Panourile de avalansa, jaloanele,
##    scree_slab, tussock, fagii — toate DINCOLO de EDGE_KEEP.
## 3. Panouri de zona de avalansa (chevron, FARA text — deci `chevron_sign`,
##    nu `road_sign_blank` cu mesaj), jaloane (`snow_pole`), `scree_slab` pe
##    panta (placa, coliziune `none`), `tussock_clump` pe platou, fagi tot mai
##    rari spre portal, `beech_dead` langa portal.
##
## ------------------------------------------------------------------------
## SURVEY (runda 1, --survey) — vezi ANTETUL DE MASURATORI de mai jos, scris
## dupa prima rulare (nu presupus).

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneE_Portal"

## Fractiile din contract (fiordland_poi_gauntlet.md): sectorul E e
## 0.424-0.612 (semilatime 6,5), portalul chiar la 0.612. Decorul incepe unde
## se termina zona D (dupa podet/torent, 0.46) si se opreste la gura
## tunelului (0.605, cu 0,7% marja inainte de portal pentru linia de oprire +
## semafor, deja fundatie).
const F_IN := 0.460
const F_OUT := 0.605
## Portalul (linia de oprire a semaforului) — capatul absolut, nimic dupa.
const F_PORTAL := 0.612

## id-urile ext_resource din Track16.tscn (fundatia + reuse deja inregistrat).
const RES := {
	"chevron_sign": "s_chevron_sign",
	"road_sign_blank": "s_road_sign_blank",
	"snow_pole": "s_snow_pole",
	"scree_slab": "s_scree_slab",
	"tussock_clump": "s_tussock_clump",
	"beech_a": "s_beech_a",
	"beech_b": "s_beech_b",
	"beech_c": "s_beech_c",
	"beech_dead": "s_beech_dead",
	"guard_rock": "s_guard_rock",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"fern_cluster": "s_fern_cluster",
	## RUNDA 3: gramezi de grohotis sub perete/pe taluz (verdict critic).
	## `s_chasm_rock` e deja ext_resource in Track16.tscn (fundatie, folosit la
	## ZoneB) — reuse, nu resursa noua.
	"chasm_rock": "s_chasm_rock",
}

## Inaltimea AABB masurata (docs/asset_briefs/fiordland_masuratori.md §1).
## Scara se cere in METRI, se imparte la cifra de aici.
const HEIGHT := {
	"chevron_sign": 1.0,       # dim necunoscuta exact in masuratori; placut la 1:1 mai jos
	"road_sign_blank": 2.450,
	"snow_pole": 2.000,
	"scree_slab": 1.196,
	"tussock_clump": 0.804,
	"beech_a": 7.030, "beech_b": 10.189, "beech_c": 13.501,
	"beech_dead": 8.515,
	"guard_rock": 0.585,
	"moss_boulder_a": 1.0, "moss_boulder_b": 1.0, "moss_boulder_c": 1.0,
	"fern_cluster": 1.0,
	"chasm_rock": 2.500,
}

## Raza de DEGAJARE la sol (m) la scara 1: raza corpului fizic.
## `beech_*` au coliziune `trunk` (raza la baza, masurata). Restul `hull` sau
## `none` (vezi COLLISION mai jos) — raza aproximata din AABB/2.
const BASE_R := {
	"chevron_sign": 0.4,
	"road_sign_blank": 0.8,
	"snow_pole": 0.03,
	"scree_slab": 4.0,      # placa 5x8, semi-latime pe X
	"tussock_clump": 0.34,
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03,
	"beech_dead": 0.68,
	"guard_rock": 0.59,
	"moss_boulder_a": 0.6, "moss_boulder_b": 1.1, "moss_boulder_c": 1.6,
	"fern_cluster": 0.5,
	"chasm_rock": 3.02,
}

## Raza COROANEI (m) la scara 1 — testul camerei / testul siluetei.
const CROWN_R := {
	"chevron_sign": 0.4,
	"road_sign_blank": 0.8,
	"snow_pole": 0.03,
	"scree_slab": 4.0,
	"tussock_clump": 0.34,
	"beech_a": 2.55, "beech_b": 3.18, "beech_c": 4.78,
	"beech_dead": 1.64,
	"guard_rock": 0.59,
	"moss_boulder_a": 0.6, "moss_boulder_b": 1.1, "moss_boulder_c": 1.6,
	"fern_cluster": 0.5,
	"chasm_rock": 3.02,
}

const TRI := {
	"chevron_sign": 40, "road_sign_blank": 36, "snow_pole": 40,
	"scree_slab": 264, "tussock_clump": 144,
	"beech_a": 228, "beech_b": 292, "beech_c": 292, "beech_dead": 136,
	"guard_rock": 72,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"fern_cluster": 150,
	"chasm_rock": 416,
}

## Coliziunea per model (decor_manual.md: hull/trunk/mesh/none). `beech_*` pe
## trunk (memoria comuna a zonelor Fiordland); `scree_slab` placa pe panta =
## `none` (contract explicit sectiunea E: "placa, `none`"); `tussock_clump`,
## `chevron_sign`, `road_sign_blank`, `snow_pole` = `none` (nu opresc masina);
## `guard_rock`/`moss_boulder_*`/`fern_cluster` = `hull` implicit.
const COLLISION := {
	"chevron_sign": "none",
	"road_sign_blank": "none",
	"snow_pole": "none",
	"scree_slab": "none",
	"tussock_clump": "none",
	"beech_a": "trunk", "beech_b": "trunk", "beech_c": "trunk",
	"beech_dead": "trunk",
	"guard_rock": "hull",
	"moss_boulder_a": "hull", "moss_boulder_b": "hull", "moss_boulder_c": "hull",
	"fern_cluster": "none",
	"chasm_rock": "hull",
}

## Degajarea minima de la MUCHIA drumului la marginea corpului fizic (m),
## pentru orice piesa cu coliziune. Portalul e pe culoarul autocarului (brief:
## "nimic pe cei 9 m ai gurii si pe aripi") — 1,0 m in loc de 0,8 (Machu
## Picchu) ca marja suplimentara pe o urcare ingusta (semilatime 6,5) cu
## autocar + AI pe banda dreapta.
const EDGE_KEEP := 1.0
## Fasia inainte de portal (frac) pe care NIMIC cu coliziune nu se aseaza,
## indiferent de degajarea laterala: aripile-palnie (cod, invizibile in decor)
## incep sa se largeasca aici, si e culoarul de convergenta al AI-ului/
## autocarului spre linia de oprire.
const PORTAL_NO_COLLISION_FRAC := 0.010   # ~21,6 m pe 2159 m de tur

## RUNDA 2 (verdict critic): "iarba goala 0-15 m de gura, fara copaci".
## PORTAL_NO_COLLISION_FRAC (21,6 m) e corect ca REGULA IMPLICITA (piese langa
## ax, gap mic — grohotis/parapetStanca), dar e o interdictie pe FRACTIE, oarba
## la distanta laterala reala. Aripile-palnie (cod, Track._build_tunnels/
## _tun_frame) exista doar pe TUNNEL_WING_LEN_M = 14,0 m din capac
## (TUNNEL_CAP_PUSH_M 0,3 inainte de gol), largindu-se de la semilatimea
## tubului (4,5) la +TUNNEL_WING_SPREAD_M (3,5) = 8,0 m la capatul lor. O
## piesa cu trunchi la 12+ m de ax (fag cu gap 5-9 m) e sigur DINCOLO de aripa
## chiar langa capac, deci n-are motiv sa fie refuzata doar fiindca fractia e
## peste prag. `PORTAL_WING_CLEAR_M` e distanta laterala minima (de la ax)
## sub care se aplica interdictia stricta pe fractie; peste ea, un `trunk`
## bine departat trece (verificat: aripa max 8,0 m + marja).
const PORTAL_WING_CLEAR_M := 10.0

## Piesele `none` (tussock/fern/snow_pole) si fagii `trunk` cu trunchi departe
## de banda pot continua mult mai aproape de capac decat PORTAL_NO_COLLISION_FRAC;
## opritorul lor e F_PORTAL minus o franjă minima, ca in nota coordonatorului
## ("ultimii ~5 m goi").
const PORTAL_NONE_STOP_FRAC := 0.0023      # ~5 m pe 2159 m — franjul cerut de critic

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
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 160925
	_survey()
	if not _survey_only:
		_avalanche_signs()
		_scree_and_tussock()
		_talus_rockfall()
		_forest_thinning()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

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
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.005
	while f <= F_PORTAL + 0.005:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), s.dot(shadow)])
		f += 0.0025
	# Pozitia nodului SemaforTunel (stalpul `trafficPoleEast` a fost eliminat,
	# vezi antetul de mai sus — HazardLamp e azi fiul direct al semaforului,
	# nimic de aliniat la un stalp care nu mai exista).
	var haz := _track.get_node_or_null("Hazarduri/SemaforTunel") as Node3D
	if haz != null:
		print("; SemaforTunel global = %s, basis.z (spre tunel) = %s" % [
			haz.global_transform.origin, haz.global_transform.basis.z])


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ compozitia

## (1) PANOURI DE ZONA DE AVALANSA + JALOANE. Chevron-uri (fara text) pe
## urcare, alternand malurile, plus un rand de jaloane (snow_pole) mai des pe
## marginea care cade — brief: "chevron-uri pe urcare".
func _avalanche_signs() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := 1.0 if k % 2 == 0 else -1.0
		_place("chevron_sign", "chevron", f, sgn, 1.2,
			_yaw_facing_road(i, sgn), 1.0, "none")
		f += _step(26.0 + _rng.randf_range(-4.0, 4.0))
		k += 1
	# Jaloanele: pe ambele margini, pas mai des, pana aproape de portal (dar
	# oprite cu marja fata de culoarul autocarului).
	f = F_IN + _step(6.0)
	var f_stop := minf(F_OUT, F_PORTAL - PORTAL_NO_COLLISION_FRAC)
	while f < f_stop:
		var i := int(f * float(n)) % n
		for sgn in [-1.0, 1.0]:
			_place("snow_pole", "jalon", f, sgn, 0.6,
				_rng.randf_range(0.0, TAU), 1.0, "none")
		f += _step(14.0 + _rng.randf_range(-2.0, 2.0))


## (2) GROHOTIS PE PANTA: `scree_slab` (placa, `none`) pe versantul dinspre
## munte, `tussock_clump` pe platou/umar, `guard_rock` rar pe marginea care
## cade. Brief: "grohotis pe panta" — masivul de granit gol e teren (nu GLB),
## scree_slab e petecele de piatra maruntita la baza lui.
func _scree_and_tussock() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	var f_stop := minf(F_OUT, F_PORTAL - PORTAL_NO_COLLISION_FRAC)
	while f < f_stop:
		var i := int(f * float(n)) % n
		var up := _uphill_side(i)
		# Placile de grohotis, in grupuri de 1-2, la degajare variabila —
		# aranjamentul-bate-numarul: nu grila, jitter pe frac si pe gap.
		var cnt := 1 + (k % 2)
		for j in cnt:
			_place("scree_slab", "grohotis", f + _step(_rng.randf_range(-3.0, 3.0)),
				up, _rng.randf_range(2.5, 9.0), _rng.randf_range(0.0, TAU),
				1.0, "none")
		# tussock pe platou (langa muchie, ambele parti)
		if _rng.randf() < 0.7:
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			_place("tussock_clump", "tussock", f + _step(_rng.randf_range(-2.0, 2.0)),
				side, _rng.randf_range(1.5, 4.5), _rng.randf_range(0.0, TAU),
				_scale_for("tussock_clump", _rng.randf_range(0.7, 1.0)), "none")
		# guard_rock rar pe marginea care cade (urcare fara parapet).
		# Gap minim 3.0: probe_manual semnaleaza "IN DRUM" orice corp cu
		# coliziune sub `half_width + ROAD_MARGIN` (2,0 m) de ax, adica sub
		# 8,5 m aici — cu gap 1,0-3,0 si raza mica, doua bucati cadeau la
		# 8,0-8,5 m (runda 1, probe_manual). 3,0-6,0 pune marginea corpului
		# la >= 9,0 m, sigur peste prag.
		if k % 4 == 0:
			var down := -up
			_place("guard_rock", "parapetStanca", f, down,
				_rng.randf_range(3.0, 6.0), _rng.randf_range(0.0, TAU),
				_scale_for("guard_rock", _rng.randf_range(0.5, 0.7)), "hull")
		f += _step(9.0 + _rng.randf_range(-2.0, 2.0))
		k += 1


## (2b) GROHOTIS PE PANTA, RUNDA 3 (verdict critic): "lipseste grohotisul de
## pe panta din jurul portalului. In referinta versantul dintre linia stancii
## si acoperisul de beton al tunelului e acoperit cu bolovani/pietris varsat,
## variat ca marime, asezat ca material cazut din perete. La noi aceeasi zona
## (deasupra si lateral de gura tunelului, prim-plan-mediu, pe toata latimea
## cadrului) e panta de iarba goala."
##
## `_scree_and_tussock` de mai sus se opreste la f_stop (~0.590, F_PORTAL minus
## PORTAL_NO_COLLISION_FRAC) si foloseste DOAR `scree_slab` (placa unica,
## coliziune `none`) rar, cu gap mare — arata ca pietre izolate pe iarba, nu ca
## material cazut din perete. Nota coordonatorului: NU `scree_slab` ca grohotis
## principal (iese placa portocaliu-nisip). Grohotisul real e GRAMEZI de
## `chasm_rock` + `guard_rock` + `moss_boulder_*` (gneis inchis, tema
## fiordland) la scari 0,3-1,2, DENSE sub peretele movilei si pe taluz, cu
## yaw/inclinare variate — plus pietre mici FARA coliziune (`scree_slab` la
## scara mica, sau `guard_rock` cu mode "none") aproape de culoar (sub 0,3 m
## sau none, ca sa nu ejecteze masina). Acopera si franjul de langa portal
## (pana la aproape F_PORTAL, ca in `_portal_fringe`), fiindca exact acolo e
## bara: "deasupra si lateral de gura tunelului" — zona care azi e goala.
func _talus_rockfall() -> void:
	var n := _track.baked.size()
	# Acopera tot sectorul, inclusiv franjul de langa portal (unde
	# `_scree_and_tussock` nu ajunge): pietrele mici `none` merg pana aproape
	# de F_PORTAL (ca tussock/fern in `_portal_fringe`), gramezile cu
	# coliziune (`hull`) respecta wing-clearance-ul ca guard_rock-ul de mai jos.
	var f_stop_hull := minf(F_OUT, F_PORTAL - PORTAL_NO_COLLISION_FRAC)
	var f_stop_none := F_PORTAL - PORTAL_NONE_STOP_FRAC
	var f := F_IN
	var k := 0
	while f < f_stop_none:
		var i := int(f * float(n)) % n
		var up := _uphill_side(i)
		# Densitatea creste spre portal (bara: cea mai deasa chiar langa gura),
		# de la 1 gramada la ~13 m pas, la 1 la ~2,5 m pas chiar langa portal
		# (runda 3b: verdictul "0,605 tot bara langa perete" a aratat ca 5 m
		# pas lasa goluri intre trunchiuri — bara arata camp CONTINUU de
		# grohotis pe toata latimea cadrului, nu pete rare).
		var t: float = clampf((f - F_IN) / (f_stop_none - F_IN), 0.0, 1.0)
		var step_m: float = lerpf(13.0, 2.5, t)
		# GRAMADA sub perete (versant, `up`): 2-4 bolovani suprapusi ca gramada
		# cazuta, nu instante izolate (aranjamentul-bate-numarul). Sub
		# f_stop_hull, gap normal (langa banda). DINCOLO de f_stop_hull (ultimii
		# ~12 m pana la portal, exact zona numita de critic: "deasupra si
		# lateral de gura tunelului") `_place` refuza orice `hull` sub
		# PORTAL_WING_CLEAR_M (10 m de ax) — deci acolo se cere explicit un gap
		# mai mare, ca piesa sa treaca de verificarea aripii (ca fagii din
		# _portal_fringe), nu se renunta la gramezi in franj.
		var near_portal := f >= f_stop_hull
		var gap0: float = (_rng.randf_range(5.0, 7.0) if near_portal
			else _rng.randf_range(1.5, 4.0))
		var cnt: int = (4 + (k % 3)) if near_portal else (3 + (k % 2))
		for j in cnt:
			var mdl: String
			var roll := _rng.randf()
			if roll < 0.4:
				mdl = "chasm_rock"
			elif roll < 0.65:
				mdl = "guard_rock"
			elif roll < 0.83:
				mdl = "moss_boulder_a"
			elif roll < 0.93:
				mdl = "moss_boulder_b"
			else:
				mdl = "moss_boulder_c"
			var scl_m: float = _rng.randf_range(0.3, 1.2)
			_place(mdl, "grohotisGramada",
				f + _step(_rng.randf_range(-2.0, 2.0)), up,
				gap0 + _rng.randf_range(0.0, 2.5) + float(j) * 0.6,
				_rng.randf_range(0.0, TAU), scl_m, "hull")
		if not near_portal:
			# Cateva si pe partea care cade (mai rare — molozul se aduna mai
			# ales sub perete, dar diorama arata si o franjura pe cealalta
			# margine a drumului).
			if _rng.randf() < 0.35:
				var down := -up
				var mdl2 := "chasm_rock" if _rng.randf() < 0.5 else "guard_rock"
				_place(mdl2, "grohotisMargine", f + _step(_rng.randf_range(-2.0, 2.0)),
					down, _rng.randf_range(3.0, 6.0), _rng.randf_range(0.0, TAU),
					_rng.randf_range(0.3, 0.8), "hull")
		# PIETRE MICI fara coliziune, aproape de culoar (sub 0,3 m efectiv,
		# deci `none`): umplu golul dintre gramada si asfalt, pe ambele parti,
		# ca materialul sa citeasca "varsat pe panta" pana la marginea drumului,
		# nu doar sub perete. Merg pana aproape de portal (f_stop_none).
		var small_cnt := 3 if near_portal else 1
		for sgn in [-1.0, 1.0]:
			for sc in small_cnt:
				if _rng.randf() < 0.85:
					var mdl3 := "guard_rock" if _rng.randf() < 0.6 else "chasm_rock"
					_place(mdl3, "grohotisMic",
						f + _step(_rng.randf_range(-1.8, 1.8)), sgn,
						_rng.randf_range(0.3, 3.0) + float(sc) * 1.5,
						_rng.randf_range(0.0, TAU),
						_rng.randf_range(0.25, 0.45), "none")
		f += _step(step_m)
		k += 1


## (3) RARIREA PADURII spre portal — fagi tot mai rari, `beech_dead` langa
## portal, bolovani cu muschi + ferigi pe versantul umed dinspre munte in
## partea de jos a zonei (unde inca e padure deasa), pas care CRESTE liniar
## spre portal (densitate care scade, nu grila). Culoarul autocarului si
## portalul insusi raman goale.
func _forest_thinning() -> void:
	var n := _track.baked.size()
	var f_stop := minf(F_OUT, F_PORTAL - PORTAL_NO_COLLISION_FRAC)
	var span := f_stop - F_IN
	var k := 0
	var f := F_IN
	while f < f_stop:
		var t: float = clampf((f - F_IN) / span, 0.0, 1.0)  # 0 la coada, 1 la portal
		# Pasul creste de la ~9 m (padure deasa, ca in D) la ~55 m (aproape gol
		# langa portal) — rarirea explicita ceruta de brief.
		var step_m: float = lerpf(9.0, 55.0, t)
		var i := int(f * float(n)) % n
		var up := _uphill_side(i)
		var mdl := "beech_c" if k % 5 == 0 else ("beech_b" if k % 2 == 0 else "beech_a")
		var h := _rng.randf_range(10.0, 13.0) if mdl == "beech_c" else (
			_rng.randf_range(7.5, 9.5) if mdl == "beech_b"
			else _rng.randf_range(5.5, 7.0))
		_place(mdl, "fag", f, up, _rng.randf_range(2.0, 6.0),
			_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
		# Bolovani cu muschi si ferigi la baza padurii, tot mai rari.
		if _rng.randf() < lerpf(0.55, 0.05, t):
			var bmdl := "moss_boulder_b" if _rng.randf() < 0.5 else "moss_boulder_a"
			_place(bmdl, "bolovanMuschi", f + _step(3.0), up,
				_rng.randf_range(1.0, 4.0), _rng.randf_range(0.0, TAU),
				_scale_for(bmdl, _rng.randf_range(0.8, 1.6)), "hull")
		if _rng.randf() < lerpf(0.45, 0.05, t):
			_place("fern_cluster", "feriga", f + _step(4.0), up,
				_rng.randf_range(1.5, 4.5), _rng.randf_range(0.0, TAU),
				_scale_for("fern_cluster", _rng.randf_range(0.6, 1.1)), "none")
		f += _step(step_m)
		k += 1
	# beech_dead langa portal — brief explicit: "beech_dead langa portal".
	# Cateva exemplare, in ultimii metri inainte de linia de oprire, PE
	# versantul dinspre munte (nu pe culoarul autocarului).
	for j in 3:
		var ff: float = f_stop - _step(3.0 + float(j) * 4.0)
		var i := int(ff * float(n)) % n
		var up := _uphill_side(i)
		_place("beech_dead", "fagUscat", ff, up, _rng.randf_range(2.5, 5.0),
			_rng.randf_range(0.0, TAU), _scale_for("beech_dead",
				_rng.randf_range(6.0, 8.0)), "trunk")
	_portal_fringe(f_stop)


## RUNDA 2 (verdict critic): "in referinta padurea vine pana aproape de tunel
## pe ambele parti si abia acolo se rareste; la noi 0-15 m de gura e iarba
## goala". `_forest_thinning` de mai sus se oprea la `f_stop` (F_PORTAL minus
## PORTAL_NO_COLLISION_FRAC, ~21,6 m) pentru TOATA vegetatia — corect pentru
## coliziune (aripile-palnie ale tunelului se intind 14,3 m din capac), gresit
## pentru piesele `none` care nu pot ejecta autocarul. Fringe-ul asta continua
## PE AMBELE FLANCURI, dincolo de aripi (verificat: aripa la +8,0 m fata de ax
## la capatul ei, deci gap-urile de mai jos pun corpul la peste 10 m de ax),
## cu densitate DESCRESCATOARE spre portal, oprindu-se la PORTAL_NONE_STOP_FRAC
## (~5 m goi, cum a cerut criticul). Piese `none`: tussock_clump, fern_cluster,
## snow_pole — plus fagi `trunk` cu gap mare (trunchi > 10 m de ax, deci in
## afara benzii autocarului de 4,5 m semilatime + aripa de 3,5 m).
func _portal_fringe(f_stop: float) -> void:
	var n := _track.baked.size()
	# NU plafonat la F_OUT: F_OUT era capatul arbitrar al zonei de rarire de
	# mai sus, nu o limita de siguranta — franjul trebuie sa ajunga aproape de
	# portalul real (F_PORTAL), altfel `min(F_OUT, ...)` il taia inapoi la
	# f_stop si franjul iese gol (bug gasit la prima rulare a rundei 2: 6,5 m
	# de span in loc de ~16,4 m).
	var f_stop_none := F_PORTAL - PORTAL_NONE_STOP_FRAC
	if f_stop_none <= f_stop:
		return
	var span := f_stop_none - f_stop
	var f := f_stop
	var k := 0
	while f < f_stop_none:
		var t: float = clampf((f - f_stop) / span, 0.0, 1.0)  # 0 la coada, 1 la portal
		# Pas care CRESTE spre portal (densitate care scade), dar mult mai
		# strans decat rarirea de mai sus — bara arata padurea venind APROAPE
		# de tunel, deci pasul ramane sub-2 m pana tarziu si creste doar in
		# ultimii metri (runda 1 avea pas 4-14 m, prea rar pentru un span de
		# 16,6 m — 3 iteratii cu roluri de probabilitate ieseau aproape goale).
		var step_m: float = lerpf(0.9, 3.2, t)
		var i := int(f * float(n)) % n
		for sgn in [-1.0, 1.0]:
			# Ciorchini, nu instante izolate (aranjamentul-bate-numarul): 1-3
			# tussock/feriga per pas per parte, densitate care scade spre t=1.
			var cnt: int = 1 + int(round(lerpf(2.0, 0.0, t)))
			for c in cnt:
				if _rng.randf() < lerpf(0.95, 0.35, t):
					_place("tussock_clump", "tussockPortal",
						f + _step(_rng.randf_range(-1.8, 1.8)), sgn,
						_rng.randf_range(1.0, 4.0), _rng.randf_range(0.0, TAU),
						_scale_for("tussock_clump", _rng.randf_range(0.7, 1.0)), "none")
				if _rng.randf() < lerpf(0.8, 0.25, t):
					_place("fern_cluster", "ferigaPortal",
						f + _step(_rng.randf_range(-1.8, 1.8)), sgn,
						_rng.randf_range(1.5, 4.5), _rng.randf_range(0.0, TAU),
						_scale_for("fern_cluster", _rng.randf_range(0.6, 1.1)), "none")
			# Fagi cu trunchi departe de banda: gap 5-9 m pune corpul (trunk,
			# raza ~0.8-1.0 m) la peste 12 m de ax — dincolo de aripa (8,0 m).
			# CIORCHINE garantat (nu coin-flip per copac): criticul a cerut
			# explicit "ciorchini de copaci", nu un fag izolat din cand in
			# cand — o singura rulare initiala a dat 1 fag pe TOT franjul (2
			# flancuri) fiindca un rol de probabilitate per iteratie, cu doar
			# 3-4 iteratii, e prea putin pentru un ciorchine vizibil. Acum:
			# 2-3 fagi garantati per pas per parte la coada (t mic), scazand
			# la 0-1 spre portal (t mare) — densitatea descrescatoare ceruta.
			var tree_cnt: int = 2 + int(round(lerpf(2.0, 0.0, t)))
			for tc in tree_cnt:
				if _rng.randf() < lerpf(1.0, 0.45, t):
					var mdl := "beech_c" if _rng.randf() < 0.3 else \
						("beech_a" if _rng.randf() < 0.6 else "beech_b")
					var h: float = _rng.randf_range(10.0, 12.5) if mdl == "beech_c" else (
						_rng.randf_range(5.5, 7.0) if mdl == "beech_a"
						else _rng.randf_range(7.5, 9.5))
					_place(mdl, "fagPortal",
						f + _step(_rng.randf_range(-2.5, 2.5)), sgn,
						_rng.randf_range(5.0, 9.0), _rng.randf_range(0.0, TAU),
						_scale_for(mdl, h), "trunk")
		f += _step(step_m)
		k += 1


## Partea dinspre munte (versant care URCA), la indexul i. Se citeste din
## teren: solul la 15/25 m lateral, dreapta fata de stanga (memoria
## aranjamentul-bate-numarul / harnasul din Machu Picchu, aici e o urcare, nu
## o serpentina, deci partea nu alterneaza pe felie — se confirma o singura
## data, dar tot din teren, nu se ghiceste).
func _uphill_side(i: int) -> float:
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var dl := 0.0
	var dr := 0.0
	for off: float in [15.0, 25.0]:
		var l := p + s * -off
		var r := p + s * off
		dl += _sol_real(l.x, l.z) - p.y
		dr += _sol_real(r.x, r.z) - p.y
	return -1.0 if dl > dr else 1.0


## Orientarea unui panou (chevron) ca sa priveasca spre axa drumului.
func _yaw_facing_road(i: int, side_sign: float) -> float:
	var s := _track._side_at(i) * side_sign
	# fata panoului spre drum = -s; yaw astfel incat local +X (fata standard
	# PaletteBox-urilor kitului) sa priveasca spre axa.
	return atan2(-(-s.z), -s.x)


# ------------------------------------------------------------------ asezarea

func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la MARGINEA corpului fizic. Cota din raycast pe TerrainBody.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String) -> void:
	var n := _track.baked.size()
	var fw := fposmod(frac, 1.0)
	var i := int(fw * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < half - 1.0:
		_warn += 1
		print("; ATENTIE silueta %s la frac %.4f ajunge la %.2f m de ax (banda %.2f)" % [
			model, frac, d - cr, half])
	# Portalul: nimic cu coliziune in fasia finala (aripile-palnie, cod) —
	# CU EXCEPTIA pieselor masurat departe de ax (d - r >= PORTAL_WING_CLEAR_M,
	# adica dincolo de aripa reala de 8,0 m + marja), care pot continua pana
	# aproape de capac (runda 2, verdict critic: "padure pana aproape de
	# tunel"). Sub acel prag lateral, interdictia pe fractie ramane absoluta.
	if mode != "none" and fw >= F_PORTAL - PORTAL_NO_COLLISION_FRAC:
		if fw >= F_PORTAL or d - r < PORTAL_WING_CLEAR_M:
			_skipped += 1
			return
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


## Cade punctul `p` pe carosabilul ALTUI tronson (nu pe cel local)? Zona E e o
## urcare dreapta (nu serpentina), dar tunelul e chiar dupa ea (frac 0.612+),
## deci se pastreaza testul — la fel ca la Machu Picchu, ca nicio piesa sa nu
## incalece un alt tronson vizibil din cadru.
const NEAR_WINDOW_FRAC := 0.012
const OTHER_ROAD_KEEP := 1.2

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
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate (cota/coliziune), %d avertismente, ~%d triunghiuri" % [_n, _skipped, _warn, _tri])
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
## campul neted (memoria terrain-mesh-y-extrapoleaza).
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
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
