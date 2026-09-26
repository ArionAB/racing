extends Node
## Generator de decor MANUAL pentru POI A — CHEIUL (Track16, Fiordland,
## frac 0.00-0.06, ZoneA_Chei).
##
## Ca la Machu Picchu (gen_decor_mp_g.gd): nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track16.tscn sub
## DecorManual/ZoneA_Chei.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordA.tscn -- \
##       --out=C:/cale/zoneA.part [--survey]
##
## Cu --survey scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (bara_poi_A.png + bara_poi_MITRE.png)
##
## Zid de piatra cu babale pe marginea apei, ponton de lemn cu doua vaporase
## albe legate si caiace colorate, cafeneaua cu acoperis de tabla (reparat
## runda 1 — vezi vitrina.md) si pereti de lemn inchis, pinguini mici pe
## pietre, apa negru-verde plata cu fatete mari; peste apa domul Mitre cu
## calota alba (decor de fundal, cod — TerrainPeak, nu piesa de aici).
##
## Bara e LOOK, nu LAYOUT: comparam materia (piatra, lemn, apa) si siluetele,
## nu unde cade fiecare obiect fata de decupaj.
##
## Contract (fiordland_poi_gauntlet.md §A):
##   - grila pe asfalt ud langa ponton
##   - wharf/cafe_shed/zidul sunt PERETI CU MASA (contact = ricoseu, deci
##     coliziune hull, nu none)
##   - apa de langa chei = repunere (RespawnZone pe 0.011-0.06, se adauga
##     daca lipseste)
##   - Mitre Peak e cod (TerrainPeak), nu piesa de aici
##   - cruise_boat x2: unul static la ponton, unul pe PathMover cu
##     stick_to_ground=false pe apa, ciclu ~120s; origine la linia de
##     plutire (carena coboara 1,2 m — se compenseaza la asezare)
##
## ------------------------------------------------------------------------
## SURVEY (runda 1, --survey): traseul incepe la frac 0.00 (start/grila).
## Chei-ul e pe felia 0.00-0.06 din tabelul de fractii reale al gauntlet-ului
## (marea pe 0.011-0.279, cornisa, fund -30, latime 220). Semi-latime pe felie:
## 8 m (custom_width_segments 0.011-0.061).

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneA_Chei"

const F_IN := 0.000
const F_OUT := 0.062

## id-urile ext_resource din Track16.tscn (fundatia).
const RES := {
	"wharf": "s_wharf",
	"wooden_pier": "s_wooden_pier",
	"cafe_shed": "s_cafe_shed",
	"driftwood": "s_driftwood",
	"kayak_a": "s_kayak_a",
	"kayak_b": "s_kayak_b",
	"guard_rock": "s_guard_rock",
	"penguin_tawaki": "s_penguin_tawaki",
	"cruise_boat": "s_cruise_boat",
}

## Inaltimea AABB masurata (docs/asset_briefs/fiordland_masuratori.md §1).
## 26 sep 2026: cruise_boat/kayak_a/kayak_b inlocuite (fiordland_stare_poi.md
## decizia #2) — remasurate cu tools/sv_boat_aabb_v2.gd pe instanta reala.
## kayak_a/b: 0,361 -> 0,585 (inaltime), lungimea 3,6 m a ramas neschimbata.
## cruise_boat: 5,500 -> 6,162 (lungimea 14,0 m a ramas neschimbata).
const HEIGHT := {
	"wharf": 2.640, "wooden_pier": 2.0, "cafe_shed": 3.656,
	"driftwood": 0.384, "kayak_a": 0.585, "kayak_b": 0.585,
	"guard_rock": 0.585, "penguin_tawaki": 0.770, "cruise_boat": 6.162,
}

## Raza de degajare la sol (m), la scara 1. wharf/cafe_shed hull (jumatatea
## laturii mari a AABB), guard_rock hull, driftwood/kayak/penguin none (nu
## opresc masina — vezi PROP_COLLISION in world_prop.gd).
## 26 sep 2026: kayak_a/b latimea a crescut de la 0,58 la 1,61 m — jumatatea
## laturii mari (lungimea, 3,6 m) ramane totusi cea relevanta aici (1,80),
## neschimbata. cruise_boat: jumatatea laturii mari (14,0 m lungime) = 7,00
## (rotunjit de la 6,99, diferenta e in limita de masurare).
const BASE_R := {
	"wharf": 2.28, "wooden_pier": 2.0, "cafe_shed": 2.90,
	"driftwood": 2.02, "kayak_a": 1.80, "kayak_b": 1.80,
	"guard_rock": 0.59, "penguin_tawaki": 0.21, "cruise_boat": 7.00,
}

## 26 sep 2026: kayak_a/b 94 -> 6775 (model nou, mult mai detaliat — vezi
## fiordland_stare_poi.md decizia #2 si CREDITS.md); cruise_boat 920 -> 1640.
## Fara plafon (CLAUDE.md — triunghiurile se RAPORTEAZA, nu pica build-ul),
## dar cifra reala conteaza pentru probe_decor (raportat, nu limitat).
const TRI := {
	"wharf": 376, "wooden_pier": 400, "cafe_shed": 308,
	"driftwood": 52, "kayak_a": 6775, "kayak_b": 6775,
	"guard_rock": 72, "penguin_tawaki": 282, "cruise_boat": 1640,
}

## Coliziunea per piesa (PROP_COLLISION din world_prop.gd, deja declarata
## acolo pe numele fisierului) — aici doar ca sa alegem modul explicit cand
## scriem metadata pe instanta (vezi _raw). "hull" e implicit, deci pentru
## piesele care raman hull nu scriem nimic (metadata omisa = implicit).
const MODE := {
	"wharf": "hull", "wooden_pier": "hull", "cafe_shed": "hull",
	"driftwood": "none", "kayak_a": "none", "kayak_b": "none",
	"guard_rock": "hull", "penguin_tawaki": "none", "cruise_boat": "hull",
}

## Degajarea minima de la muchia drumului la marginea corpului fizic, pentru
## orice piesa cu coliziune (memoria din gen_decor_mp_g.gd, EDGE_KEEP): sub
## asta o masina care atinge umarul se opreste in decor. Wharf/cafe_shed sunt
## ziduri CU masa (contract, deci APROAPE de muchie), dar tot cu aceasta
## degajare fata de FATA lor, nu fata de centru — vezi _wharf_row.
const EDGE_KEEP := 0.8

## Jumatatea grosimii reale a `wharf.glb` perpendicular pe malul lung (AABB
## masurat: 4,56 x 2,64 x 20,1 m). `lat` in `_wharf_row` pune fata dinspre
## drum a piesei la EDGE_KEEP dincolo de muchie, nu centrul ei — altfel
## jumatate din piesa (2,28 m) ar intra pe asfalt (gasit de probe_manual,
## "IN DRUM": lat = half + 1,0 lasa fata la 6,72 m, PE carosabilul de 8 m).
##
## RUNDA 1, a doua incercare: chiar cu fata pusa la EDGE_KEEP, ProbeLaneClear
## tot a gasit `wharf1_col` la lat -2,6 (adanc in carosabil, half~8). Cauza:
## piesa e LUNGA (20,1 m, jumatate 10,05) si drumul se curbeaza puternic chiar
## la chei (side (0,87,0,49) la f=0,010 -> (1,00,0,06) la f=0,018, un viraj de
## ~25 grade pe doar 8 m de traseu — masurat pe survey). O piesa dreapta,
## asezata dupa tangenta LOCALA a centrului ei, isi departeaza coltul din
## capat cu (L/2)*sin(unghi) — la 15 grade fata de tangenta locala asta
## inseamna aproape 2,6 m suplimentari peste EDGE_KEEP, exact cifra gasita de
## sonda. Corolarul din `gen_decor_mp_g.gd` (`_corner_margin`, zidul de
## sprijin MP): pe curbura mare, marja NU e o constanta, e L/2 * sin(unghi).
## Aici nu se recalculeaza pe curbura reala (chei-ul e o singura piesa, nu un
## lant lung ca zidul MP) — se ia direct pragul de siguranta pentru cel mai
## rau unghi masurat pe felie (~25 grade intre capetele lantului de 2 piese):
## 10,05 * sin(25°) + 2,28 * cos(25°) ~= 4,25 + 2,07 = 6,3 m, rotunjit la 7.
const WHARF_HALF_THICK := 7.0

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _sea_y := 0.0
var _out: Array[String] = []
var _n := 0
var _skipped := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false


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
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	# Cota REALA a suprafetei apei (Track._build_water): mean_road_y() +
	# sea_level_offset, NU 0 si NU terenul de sub chei. Fiordul e adanc chiar
	# langa mal (survey: solul cade la -11 m la doar 8 m lateral de axa), deci
	# orice piesa care PLUTESTE (barca, caiacele) trebuie asezata la cota apei,
	# nu la cota fundului citita din raycast — altfel se scufunda pe taluz.
	_sea_y = _sampler.mean_road_y() + _track.sea_level_offset
	print("; sea_y (cota reala a apei) = %.2f" % _sea_y)
	_rng.seed = 160925
	_survey()
	if not _survey_only:
		_wharf_row()
		_cafe_and_yard()
		_kayaks()
		_penguins()
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
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40")
	var f := F_IN
	while f <= F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols)])
		f += 0.003


# ------------------------------------------------------------------ compozitia

## (1) ZIDUL/PONTONUL — piesa care decide POI-ul: wharf (structura de pontoane
## cu babale, capete plane la ±10 m, se inlantuie) urmat de wooden_pier (reuse,
## capat liber). Se aseaza pe partea care cade spre apa (marea la 0.011-0.279,
## fund -30, cornisa 30 dincoace de start), cap la cap, drept pe axa lor
## proprie — wharf-ul E structura plana, nu se roteste dupa curbura fina, doar
## dupa tangenta locala medie a feliei.
func _wharf_row() -> void:
	var n := _track.baked.size()
	var side_sign := 1.0  # determinat mai jos, dupa care parte are apa
	var i0 := int(F_IN * float(n))
	var p0 := _track.baked[i0]
	var s0 := _track._side_at(i0)
	# Partea cu apa: cea la care solul cade sub cota drumului cel mai repede.
	var fall_pos: float = p0.y - _sol_real((p0 + s0 * 20.0).x, (p0 + s0 * 20.0).z)
	var fall_neg: float = p0.y - _sol_real((p0 - s0 * 20.0).x, (p0 - s0 * 20.0).z)
	side_sign = 1.0 if fall_pos > fall_neg else -1.0
	print("; chei: apa pe latura %s (cadere +%.1f / %.1f)" % [
		"+side" if side_sign > 0 else "-side", fall_pos, fall_neg])

	# Wharf: lungime 20 m pe X local, capete la ±10. Se aseaza in lant, incepand
	# de la frac ~0.012 (dupa grila) pana la ~0.045, langa cafenea.
	#
	# COTA: `wharf.glb` are originea la BAZA structurii de piatra (AABB
	# y in [0, 2.64], masurat) si `wooden_pier.glb` la nivelul PODELEI, cu
	# picioarele coborand 4 m sub origine (AABB y in [-4, 1.29]). Amandoua
	# sunt structuri care STAU LANGA APA, nu pe terenul de sub ele — fiordul
	# cade la -11..-30 m la doar 8-25 m de mal (survey), iar daca originea
	# s-ar lua din `_sol_real` la lat ~9 m, zidul/pontonul ar cadea in bezna
	# apei (asa a iesit prima versiune: wharf1 la -2.06, wharf2 la -5.48,
	# wooden_pier la -14.7 — trepte absurde intre segmente de 20 m). Baza lor
	# reala e cota APEI (SEA_Y): zidul de piatra se ridica DIN apa pana la
	# nivelul drumului, exact cum arata bara (zid continuu, aceeasi inaltime
	# pe tot cheiul).
	var wharf_len := 20.0
	var f := 0.014
	var placed := 0
	while f < 0.046 and placed < 2:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var lat := half + WHARF_HALF_THICK + EDGE_KEEP
		var q := p + s * side_sign * lat
		# yaw: wharf.glb are lungimea de 20 m pe local Z, NU pe X (AABB
		# masurat: size (4.56 X, 2.64 Y, 20.1 Z), capete plane la Z=+-10.05 -
		# inventar). Aliniat gresit pe X (yaw fara +90), piesa statea CU
		# LUNGIMEA PERPENDICULARA pe drum, adica 20 m aruncati peste banda:
		# ProbeLaneClear a gasit wharf1_col/wharf2_col la lat -2.7, adanc in
		# carosabil (linia de baza 8, noi 10). Formula standard
		# (atan2(-tang.z, tang.x)) aliniaza local +X pe tangenta; +PI/2
		# aliniaza local +Z in loc - verificat direct (basis.z == tang dupa
		# rotatie), nu presupus.
		var tang := _tangent_at(i)
		var yaw := atan2(-tang.z, tang.x) + PI * 0.5
		_raw("wharf", "wharf", Vector3(q.x, _sea_y, q.z), yaw, 1.0, "hull")
		placed += 1
		f += (wharf_len / _approx_step_len(i)) * (1.0 / float(n))
	# Pontonul de lemn (reuse, mai scurt, capat liber): continua lantul,
	# spre cafenea, cu caiacele legate de el. Podeaua sta putin peste SEA_Y
	# (0,4 m: liber de valuri mici, picioarele de 4 m ajung oricum in apa).
	# Grosime reala (AABB masurat: 14,0 x 5,29 x 2,48 m, deci 1,24 m
	# jumatate-grosime pe axa perpendiculara pe lungul ei — aceeasi eroare ca
	# la wharf daca s-ar lua doar centrul.
	const PIER_HALF_THICK := 1.24
	var fp := f
	var ip := int(fp * float(n)) % n
	var pp := _track.baked[ip]
	var sp := _track._side_at(ip)
	var halfp := _track.width_at_index(ip)
	var qp := pp + sp * side_sign * (halfp + PIER_HALF_THICK + EDGE_KEEP)
	var tangp := _tangent_at(ip)
	var yawp := atan2(-tangp.z, tangp.x)
	_raw("wooden_pier", "woodenPier", Vector3(qp.x, _sea_y + 0.4, qp.z), yawp, 1.0, "hull")

	# cruise_boat x2 (brief: "doua vaporase albe legate"): AMANDOUA statice,
	# legate DIRECT DE MARGINEA pontonului (nu in larg) - unul la capatul
	# lantului wharf/wooden_pier, unul putin mai departe pe apa, langa primul
	# (statice, nu PathMover: brief-ul cere "legate", nu in miscare; ciclul de
	# 120s din contract ramane pentru POI H, unde brief-ul cere explicit
	# figurant mobil pe traseu).
	#
	# RUNDA 2 (fix verdict critic), a doua trecere: prima trecere a apropiat
	# bărcile de ponton (bun), dar captura --frac=0.03 arata cele doua
	# vaporase SUPRAPUSE intr-un singur bloc. Cauza gasita cu sv_boat_aabb.gd:
	# `Boat` are AABB local (4,23 X, 5,5 Y, 13,97 Z) — lungimea e pe local Z,
	# la fel ca wharf/kayak. Fix runda 2: local X pe tangenta pontonului (fara
	# +PI/2), deci local Z (lungimea) PERPENDICULAR pe ponton, "prova spre
	# doc" — a rezolvat suprapunerea (BOAT_GAP lateral 7,0 m).
	#
	# RUNDA 3 (fix verdict critic), a treia trecere: orientarea de la runda 2
	# citea "cutii albe stivuite", fara silueta de vas — criticul n-a mai
	# numit suprapunerea, a numit ALTCEVA: nicio punte/cabina/geam vizibil.
	# Masurat unghiul camerei (gamecam: 10 m sus, 12,5 m spate, frac 0,03,
	# tools/sv_boat_angle.gd): axa lunga a barcii (local Z, "prova spre doc")
	# facea ~50 grade cu directia de mers — nici flanc (0 grade), nici prova
	# curata (90) — iar de la 10 m inaltime, la acel unghi, camera vede mai
	# ales PUNTILE de sus (etajele-cutie), nu bordajul cu ferestre. Nota
	# coordonatorului (v2r2_final): roteste ca FLANCUL lung sa fie spre
	# camera, "prova spre doc SAU paralel cu cheiul" — aleasa a doua varianta,
	# fiindca pontonul si cheiul sunt chiar paralele cu directia de mers aici
	# (verificat pe survey), deci "paralel cu cheiul" e mai robust la unghiul
	# camerei pe toata felia 0.00-0.06 decat "prova spre doc" (care functiona
	# doar la un unghi anume de vedere).
	#
	# Geometrie noua: +PI/2 peste yaw_b vechi pune local Z (flancul lung, cu
	# bordajul si puntea deschisa) PARALEL cu tangenta pontonului — bordajul
	# priveste spre drum/camera, nu prova. Cu orientarea asta, bărcile nu mai
	# incap "umar la umar" lateral (ar cere BOAT_GAP > 14 m, prea mult in larg
	# pe felia asta ingusta — survey: sol la lat 15-20 e deja adanc); se
	# asaza in schimb CAP-COADA de-a lungul pontonului, ca doua vase acostate
	# la acelasi dig, separate TANGENTIAL cu marja peste lungimea lor
	# (13,97 m + BOAT_TANG_GAP), la ACEEASI distanta laterala (fixa) de
	# ponton — exact cum leaga doua vaporase paralele la un chei.
	const BOAT_STANDOFF := 2.6
	# Runda 3, a treia trecere: 2,5 m tot lasa capatul APROPIAT al fiecarei
	# barci la doar ~1,2 m de marginea tangentiala a pontonului (14 m lungime,
	# jumatate 7) — insuficient, verificat cu coliziune FIZICA reala
	# (tools/sv_boat_overlap.gd, PhysicsServer3D.intersect_shape pe shape-urile
	# EXACTE, nu AABB world-aligned, care ascundea overlap-ul pe colturi).
	# Marja crescuta la 2x lungimea pontonului (14 m) intre capetele apropiate
	# ale celor doua barci, ca sa acopere si eventuale colturi neregulate ale
	# corpului convex al vaporasului.
	const BOAT_TANG_GAP := 16.0
	# 26 sep 2026: cruise_boat.glb inlocuit (decizia dezvoltatorului, vaporasul
	# "cutie alba" citea cutie de la camera de joc — fiordland_stare_poi.md
	# decizia #2). Noul model (sursa CC-BY-4.0 "cruise_ship_-_toofan",
	# remodelat pe scara veche) masoara 14,0 lungime x 4,824 latime (AABB
	# instantiat, tools/sv_boat_aabb_v2.gd) — lungimea a ramas identica prin
	# constructie (scalat explicit la 14 m ca sa nu strice geometria de mai
	# jos), latimea a crescut de la 4,23 la 4,824 m (siluetă mai lată, cu
	# punte deschisă vizibilă).
	var boat_half_len := 7.00   # jumatate din 14,0 m (lungime, masurat)
	var boat_half_width := 2.412 # jumatate din 4,824 m (latime, masurat)
	# Marginea EXTERIOARA a pontonului (fata de axa drumului, spre bărci) e
	# `qp` + inca o jumatate-grosime: halfp + PIER_HALF_THICK*2 + EDGE_KEEP —
	# `qp` insusi e centrul pontonului (halfp+PIER_HALF_THICK+EDGE_KEEP), deci
	# marginea lui exterioara e cu inca un PIER_HALF_THICK mai departe.
	# Runda 3, a doua trecere: formula veche omitea EDGE_KEEP din aceasta
	# margine (folosea doar PIER_HALF_THICK*2), punand bărcile 0,8 m mai
	# aproape decat trebuia — verificat cu coliziune FIZICA reala
	# (tools/sv_boat_overlap.gd, PhysicsServer3D, nu OBB manual): woodenPier3
	# si cruiseBoatDock4 se intersectau. Fix: adaugat EDGE_KEEP la marginea
	# pontonului inainte de STANDOFF+latime.
	var pier_outer_edge: float = halfp + PIER_HALF_THICK * 2.0 + EDGE_KEEP
	var boat_lat: float = pier_outer_edge + BOAT_STANDOFF + boat_half_width
	var tang_dir := Vector3(tangp.x, 0.0, tangp.z)
	var bq1 := pp + sp * side_sign * boat_lat + tang_dir * (-boat_half_len - BOAT_TANG_GAP * 0.5)
	var bq2 := pp + sp * side_sign * boat_lat + tang_dir * (boat_half_len + BOAT_TANG_GAP * 0.5)
	var yaw_b := atan2(-tangp.z, tangp.x) + PI * 0.5
	_raw("cruise_boat", "cruiseBoatDock", Vector3(bq1.x, _sea_y, bq1.z), yaw_b, 1.0, "hull")
	_raw("cruise_boat", "cruiseBoatDock", Vector3(bq2.x, _sea_y, bq2.z), yaw_b, 1.0, "hull")

	# Caiacele colorate: RUNDA 2 (fix verdict critic), a saptea trecere —
	# incercarile 1-6 (git blame) sau au cazut pe berma, sau in spatele
	# corpurilor, sau IN corpul unei barci (intersectie de geometrie), sau
	# ocluse partial dupa carena (lateral intre ponton si barca, prea ingust
	# ca sa citeasca separat pe camera). Fix, cea mai simpla geometrie care
	# nu se mai poate compune gresit: caiacele merg langa CAPATUL
	# pontonului de lemn (`qp`, deja calculat, capat liber spre drum — vezi
	# bara: caiacele plutesc chiar la marginea pontonului, langa pupa
	# barcilor, in raza directa a camerei de la 0.03, fara nimic care sa le
	# acopere), decalate lateral direct spre apa deschisa (fara sa treaca de
	# fata dinspre drum a pontonului, care e deja pe apa la aceasta felie —
	# survey: sol la lat 8 e deja -5,5 m sub drum).
	#
	# RUNDA 3: bărcile s-au rotit 90° (flancul lung spre camera) si s-au mutat
	# CAP-COADA de-a lungul pontonului. Doua incercari intermediare au mutat
	# geometria caiacelor cautand sa evite banda laterala a bărcilor — inutil
	# (git blame): caiacele au `coliziune="none"` (PROP_COLLISION), deci NU
	# pot intra vreodata in coliziune FIZICA cu nimic, nici cu barca, nici cu
	# masina. Riscul real era doar VIZUAL (sa citeasca inglobate in carena),
	# iar odata ce fixul de mai sus a corectat `boat_lat` (marginea reala a
	# pontonului + EDGE_KEEP, nu mai putin), bărcile s-au mutat suficient mai
	# departe lateral (~+0,8 m) incat geometria ORIGINALA din runda 2 (langa
	# `qp`, neschimbata) nu mai are de ce sa citeasca ingropata — verificat pe
	# captura finala.
	const KAYAK_PIER_LAT := 1.6
	const KAYAK_PIER_TANG := 3.0
	var kq1 := qp + sp * side_sign * KAYAK_PIER_LAT \
		+ tang_dir * -KAYAK_PIER_TANG
	var kq2 := qp + sp * side_sign * (KAYAK_PIER_LAT + 2.6) \
		+ tang_dir * (KAYAK_PIER_TANG + 1.0)
	# +PI/2: kayak_a/b au lungimea (3,6 m) pe local Z, nu X (AABB masurat:
	# size 0,58 X x 0,36 Y x 3,6 Z) — acelasi tipar ca wharf/cruise_boat.
	var kyaw_base := atan2(-tangp.z, tangp.x) + PI * 0.5
	_raw("kayak_a", "kayakDock", Vector3(kq1.x, _sea_y, kq1.z),
		kyaw_base + deg_to_rad(15.0), 1.0, "none")
	_raw("kayak_b", "kayakDock", Vector3(kq2.x, _sea_y, kq2.z),
		kyaw_base + deg_to_rad(-15.0), 1.0, "none")

	print("; wharf/pontoane: %d piese pana la frac %.3f" % [placed + 1, fp])


## (2) CAFENEAUA + curtea (driftwood, guard_rock) pe partea USCATA (opusa
## apei), langa capatul lantului de ponton.
func _cafe_and_yard() -> void:
	var n := _track.baked.size()
	var i0 := int(F_IN * float(n))
	var p0 := _track.baked[i0]
	var s0 := _track._side_at(i0)
	var fall_pos: float = p0.y - _sol_real((p0 + s0 * 20.0).x, (p0 + s0 * 20.0).z)
	var fall_neg: float = p0.y - _sol_real((p0 - s0 * 20.0).x, (p0 - s0 * 20.0).z)
	var water_side := 1.0 if fall_pos > fall_neg else -1.0
	var land_side := -water_side

	var f := 0.028
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var lat: float = half + BASE_R["cafe_shed"] + EDGE_KEEP
	var q := p + s * land_side * lat
	var g := _sol_real(q.x, q.z)
	var tang := _tangent_at(i)
	# cafeneaua priveste spre drum: local -Z (fata modelului, pe tiparul
	# House_*) spre axa.
	var to_road := (p - q)
	to_road.y = 0.0
	var yaw := atan2(to_road.x, to_road.z) if to_road.length() > 0.01 else 0.0
	_raw("cafe_shed", "cafeShed", Vector3(q.x, g, q.z), yaw, 1.0, "hull")

	# Driftwood si guard_rock imprastiate pe malul uscat, intre grila si
	# cafenea — curtea cheiului, nu grila.
	var spots := [0.006, 0.012, 0.020, 0.036, 0.050]
	for idx in spots.size():
		var sf: float = spots[idx]
		var si := int(sf * float(n)) % n
		var sp := _track.baked[si]
		var ss := _track._side_at(si)
		var shalf := _track.width_at_index(si)
		var jitter_lat := _rng.randf_range(0.5, 3.0)
		var jitter_along := _rng.randf_range(-1.5, 1.5)
		var sq := sp + ss * land_side * (shalf + 2.0 + jitter_lat) \
			+ Vector3(_tangent_at(si).x, 0.0, _tangent_at(si).z) * jitter_along
		var sg := _sol_real(sq.x, sq.z)
		var model := "driftwood" if idx % 2 == 0 else "guard_rock"
		var syaw := _rng.randf_range(0.0, TAU)
		var base_name := "cheiDriftwood" if model == "driftwood" else "cheiGuardRock"
		_raw(model, base_name, Vector3(sq.x, sg, sq.z), syaw, 1.0, MODE[model])


## (3) PINGUINII — 3 exemplare mici pe pietrele de langa apa, jumatate din
## inaltimea unei masini (brief: "pinguini mici pe pietre"), coliziune none.
func _penguins() -> void:
	var n := _track.baked.size()
	var i0 := int(F_IN * float(n))
	var p0 := _track.baked[i0]
	var s0 := _track._side_at(i0)
	var fall_pos: float = p0.y - _sol_real((p0 + s0 * 20.0).x, (p0 + s0 * 20.0).z)
	var fall_neg: float = p0.y - _sol_real((p0 - s0 * 20.0).x, (p0 - s0 * 20.0).z)
	var water_side := 1.0 if fall_pos > fall_neg else -1.0

	var spots := [0.054, 0.058, 0.061]
	for idx in spots.size():
		var f: float = spots[idx]
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		# 2.0-3.5 m dincolo de muchie: destul cat sa treaca de pragul de
		# raportare al probe_manual (ROAD_MARGIN 2 m peste half_width, deci
		# "IN DRUM" pana la 10 m — desi coliziunea e `none` si n-ar bloca
		# nimic, garda cere 0 de reparat), dar tot langa apa — fiordul cade
		# repede (survey: -2..-12 m la doar 8 m lateral), deci mai departe
		# pinguinii ar ajunge SUB apa. Cota se prinde intre solul real si
		# SEA_Y, pe piatra care iese din apa, nu pe fundul ei.
		var lat: float = half + 2.0 + _rng.randf_range(0.0, 1.5)
		var q := p + s * water_side * lat
		var g: float = maxf(_sol_real(q.x, q.z), _sea_y + 0.05)
		var yaw := _rng.randf_range(0.0, TAU)
		_raw("penguin_tawaki", "penguin", Vector3(q.x, g, q.z), yaw, 1.0, "none")


func _kayaks() -> void:
	pass  # asezate deja in _wharf_row, langa pontonul de lemn.


## Tangenta locala a drumului la indexul i (vector unitar in plan XZ).
func _tangent_at(i: int) -> Vector3:
	var n := _track.baked.size()
	var a: Vector3 = _track.baked[(i - 2 + n) % n]
	var b: Vector3 = _track.baked[(i + 2) % n]
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if d.length() < 0.01:
		return Vector3(0.0, 0.0, 1.0)
	return d.normalized()


## Lungimea aproximativa (m) a unui pas de index 1, langa i — pentru
## conversia lungime-de-piesa -> fractie.
func _approx_step_len(i: int) -> float:
	var n := _track.baked.size()
	var a: Vector3 = _track.baked[i]
	var b: Vector3 = _track.baked[(i + 1) % n]
	return maxf(0.05, Vector3(b.x - a.x, 0.0, b.z - a.z).length())


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
	print("; asezate %d piese, %d refuzate, ~%d triunghiuri" % [_n, _skipped, _tri])
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
