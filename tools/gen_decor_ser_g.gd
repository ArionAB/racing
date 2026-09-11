extends Node
## Generator de decor MANUAL pentru POI G — FUNDUL CRATERULUI (Track14,
## Serengeti, frac 0.715-0.853). Nu e sonda: CALCULEAZA transformarile care se
## lipesc in Track14.tscn sub `DecorManual/ZoneG_FundulCraterului`, cu cotele
## luate din coliziunea reala a terenului (raza pe `TerrainBody`), nu din
## `_terrain_mesh_y` (memoria `terrain-mesh-y-extrapoleaza`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerG.tscn -- --dump
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerG.tscn
##
## `--dump` tipareste geometria intervalului (punct pe ax, latura, semilatime,
## cota terenului si amestecul de laguna la cateva degajari, directia umbrei)
## — masuratoarea pe care s-a construit compozitia de mai jos. Fara `--dump`
## scrie nodurile.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneG_FundulCraterului"

var _track: Track
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _rng := RandomNumberGenerator.new()
var _sea_y := -1e9


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_sea_y = _track._sampler.mean_road_y() + _track.sea_level_offset
	_rng.seed = 140701
	if "--arc" in OS.get_cmdline_user_args():
		_arc_dump()
	elif "--dump" in OS.get_cmdline_user_args():
		_dump()
	else:
		_compose()
		print("")
		for line in _out:
			print(line)
		print("; asezate %d piese, %d avertismente" % [_n, _warn])
	get_tree().quit(0)


## Ce ARC din conturul lacului vede soferul. Pentru cateva fractii pun camera
## unde o pune ChaseCamera (10 m sus, 12,5 m in spate) si masor, pentru fiecare
## punct de pe poligonul lacului, daca intra in frustumul orizontal (FOV 68,
## ecran 16:9 => semiunghi orizontal ~ 54 grade). Rezultatul spune pe ce sector
## de unghi merita pus inelul de flamingi, in loc sa-l intind pe tot lacul.
func _arc_dump() -> void:
	var poly: PackedVector2Array = _track._lagoon_poly()
	var c := Vector2.ZERO
	for q in poly:
		c += q
	c /= float(poly.size())
	print("; centru lac (%.1f, %.1f), apa la y=%.2f" % [c.x, c.y, _sea_y])
	for f in [0.760, 0.770, 0.775, 0.780, 0.790, 0.800]:
		var n := _track.baked.size()
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var fwd := (_track.baked[(i + 4) % n] - p)
		fwd.y = 0.0
		fwd = fwd.normalized()
		var eye := p - fwd * 12.5 + Vector3.UP * 10.0
		var lo := 999.0
		var hi := -999.0
		var seen := 0
		# esantionez conturul des, nu doar varfurile
		for k in 360:
			var ang := float(k)
			var rr := 0.0
			# raza poligonului pe directia `ang`, prin cautare pe segmente
			var dir := Vector2(cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
			var best := -1.0
			for j in poly.size():
				var a2 := poly[j] - c
				var b2 := poly[(j + 1) % poly.size()] - c
				var d1 := a2.cross(dir)
				var d2 := b2.cross(dir)
				if (d1 <= 0.0 and d2 > 0.0) or (d1 > 0.0 and d2 <= 0.0):
					var t := absf(d1) / maxf(0.0001, absf(d1) + absf(d2))
					var hit := a2.lerp(b2, t)
					if hit.dot(dir) > 0.0:
						best = hit.length()
			if best < 0.0:
				continue
			rr = best
			var w := Vector3(c.x + dir.x * rr, _sea_y, c.y + dir.y * rr)
			var rel := w - eye
			rel.y = 0.0
			var dist := rel.length()
			if dist > 260.0:
				continue
			var horiz := rad_to_deg(acos(clampf(rel.normalized().dot(fwd), -1.0, 1.0)))
			if horiz <= 54.0:
				seen += 1
				lo = minf(lo, ang)
				hi = maxf(hi, ang)
		print("; frac %.3f  ochi (%.1f, %.1f)  puncte de contur vizibile: %d  arc %.0f..%.0f grade"
			% [f, eye.x, eye.z, seen, lo, hi])


# ------------------------------------------------------------------ masuratori

func _dump() -> void:
	var n := _track.baked.size()
	var sun: DirectionalLight3D = null
	for c in _track.get_children():
		if c is DirectionalLight3D:
			sun = c
	if sun != null:
		var d := -sun.global_transform.basis.z
		print("; soare: lumina merge spre (%.3f, %.3f, %.3f); umbra pe XZ spre (%.3f, %.3f)"
			% [d.x, d.y, d.z, d.x, d.z])
	print("; sea_y = %.2f (mean_road_y %.2f + offset %.2f)" % [_sea_y,
		_track._sampler.mean_road_y(), _track.sea_level_offset])
	print("; frac    idx      ax(x,y,z)           side(x,z)   hw    dist_lac_ax | teren la -side: 3 8 15 25 | +side: 3 8 15 25 | lag +side 8 15 25")
	var f := 0.700
	while f <= 0.870 + 1e-6:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var hw := _track.width_at_index(i)
		var lag_d := _lagoon_signed_dist(p.x, p.z)
		var cols := ""
		for sgn: float in [-1.0, 1.0]:
			for off: float in [3.0, 8.0, 15.0, 25.0]:
				var q: Vector3 = p + s * sgn * (hw + off)
				cols += " %6.2f" % (_sol_real(q.x, q.z) - p.y)
			cols += " |"
		for off: float in [8.0, 15.0, 25.0]:
			var q: Vector3 = p + s * (hw + off)
			cols += " %.2f" % _track._sampler._lagoon_mix(q.x, q.z)
		print("; %.3f %5d (%7.1f,%6.2f,%7.1f) (%5.2f,%5.2f) %4.1f %7.1f |%s" % [
			f, i, p.x, p.y, p.z, s.x, s.z, hw, lag_d, cols])
		f += 0.005
	# Punctele candidate din brief pentru elefanti + vartej: fractia lor reala.
	for c: Vector3 in [Vector3(-20, 0, -16), Vector3(35, 0, -30), Vector3(10, 0, -52),
			Vector3(-55, 2, 40)]:
		var i := _track._closest_baked_index(c)
		var p := _track.baked[i]
		print("; candidat (%.0f, %.0f): frac %.4f, ax la (%.1f, %.2f, %.1f), la %.1f m de ax, lag %.2f, sol %.2f"
			% [c.x, c.z, _track.frac_at(i), p.x, p.y, p.z,
			Vector2(c.x - p.x, c.z - p.z).length(),
			_track._sampler._lagoon_mix(c.x, c.z), _sol_real(c.x, c.z)])


## Distanta cu semn de la un punct la conturul lagunei (negativ = in lac).
func _lagoon_signed_dist(x: float, z: float) -> float:
	var poly: PackedVector2Array = _track._lagoon_poly()
	if poly.size() < 3:
		return 1e9
	var p := Vector2(x, z)
	var d_sq := INF
	for i in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
		d_sq = minf(d_sq, p.distance_squared_to(q))
	var sd := sqrt(d_sq)
	if Geometry2D.is_point_in_polygon(p, poly):
		sd = -sd
	return sd


## Cota SOLULUI din coliziunea reala a panzei de teren (raza in jos, doar pe
## `TerrainBody`); cade pe camp doar daca nu exista panza acolo.
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
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
	return _track._sampler.ground_y(x, z)


# ------------------------------------------------------------------ compozitia

func _compose() -> void:
	# Compozitia POI G. Fiecare piesa se aseaza fata de AXA soselei la o
	# fractie masurata (`_at`), la o distanta laterala de MARGINEA benzii si cu
	# semnul benzii: +1 = DREAPTA soferului (verificat: side_at ~ forward x UP
	# la 0.77), unde e lacul; -1 = STANGA, unde sta padurea Lerai.
	_out.append("[node name=\"ZoneG_FundulCraterului\" type=\"Node3D\" parent=\"DecorManual\"]")
	_approach()
	_lake_shore()
	_lerai()
	_balloon_camp()
	_to_gap()


## 0.715-0.752: intrarea pe crusta. Silueta se construieste din arbori de
## savana la 8-27 m pe STANGA (terenul urca acolo pana la +8 m la 0.735, deci
## coroanele se etajeaza) si musuroaie/euphorbia aproape de banda.
func _approach() -> void:
	var trees := [
		[0.716, -1.0, 13.0, "s_acacia_umbrella_a", 1.15],
		[0.719, -1.0, 24.0, "s_acacia_umbrella_c", 1.30],
		[0.723, -1.0, 10.0, "s_fever_tree", 1.00],
		[0.727, -1.0, 19.0, "s_acacia_umbrella_b", 1.20],
		[0.731, -1.0, 12.0, "s_acacia_umbrella_a", 0.95],
		[0.734, -1.0, 27.0, "s_baobab", 0.85],
		[0.738, -1.0, 9.0, "s_dead_tree", 1.10],
		[0.742, -1.0, 16.0, "s_acacia_umbrella_c", 1.05],
		[0.746, -1.0, 11.0, "s_fever_tree", 0.90],
		[0.750, -1.0, 21.0, "s_acacia_umbrella_a", 1.25],
		[0.7205, -1.0, 17.0, "s_acacia_umbrella_b", 1.10],
		[0.726, 1.0, 32.0, "s_acacia_umbrella_a", 1.20],
		[0.733, 1.0, 12.0, "s_dead_tree", 1.00],
		[0.741, 1.0, 18.0, "s_acacia_umbrella_c", 0.95],
	]
	for t: Array in trees:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			t[4] as float, _rng.randf() * TAU)
	var small := [
		[0.717, 1.0, 7.0, "s_termite_mound_a"],
		[0.724, -1.0, 6.5, "s_euphorbia"],
		[0.728, 1.0, 8.0, "s_termite_mound_b"],
		[0.736, -1.0, 7.5, "s_termite_mound_a"],
		[0.744, 1.0, 6.0, "s_euphorbia"],
		[0.748, -1.0, 8.5, "s_termite_mound_b"],
	]
	for t: Array in small:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			_rng.randf_range(0.9, 1.3), _rng.randf() * TAU)


## 0.770-0.800, DREAPTA: lacul de soda. Lacul a fost MUTAT in runda 2 la
## (-55, -30), R 38 x 1.15/0.95: pe traseul vechi (centru (0,-68)) apa statea la
## 89-130 grade fata de directia de mers pe TOATA felia 0.77-0.85, adica in
## spatele soferului - masurat 0.00% pixeli de apa la --frac=0.77. Acum drumul
## MERGE SPRE lac de la 0.72 (unghi 15 grade, 140 m) la 0.775 (26 m), si trece
## pe langa mal la 0.78-0.79 (20-22 m de ax, amestec de laguna 0.51-1.00).
## Flamingii vin in TREI stoluri care isi cauta singure linia apei: unul
## aproape (se citesc individual), doua pe malul din departare, ca banda roz.
## Hoitul cu vulturi sta la 9 m de banda, ca in referinta.
func _lake_shore() -> void:
	# Stoluri DESE si APROAPE: la 34-40 m raza, 150 de pasari de 1,27 m se
	# imprastie pe 3600 m2 si dispar in crusta (masurat pe G_r1_lac.png: 430
	# de flamingi asezati, zero vizibili). Referinta are o BANDA roz continua
	# pe mal — deci raza mica si numar mare, plus un stol chiar langa banda.
	# Un rand de flamingi MODELATI langa banda, ca sa se vada individual la
	# 8-14 m (stolurile MultiMesh de pe mal sunt la 25-40 m si citesc doar ca
	# banda roz). Sunt fantome (world_prop: "none"), deci nu ating masina.
	# Randul de pasari MODELATE se aseaza pe linia apei masurata la fiecare
	# fractie (`_shore_dist`), nu la o degajare fixa: se citesc individual la
	# 8-14 m si stau CU PICIOARELE la mal, ca in referinta, in loc sa fie
	# jumatate inecate si jumatate in mijlocul crustei.
	var ff := 0.7680
	while ff < 0.8000:
		var sh := _shore_dist(ff, 1.0, 46.0)
		if sh > 0.0:
			_put("s_flamingo" if _rng.randf() > 0.28 else "s_flamingo_wings",
				ff, 1.0, sh - _rng.randf_range(0.5, 2.5),
				_rng.randf_range(0.95, 1.15), _rng.randf() * TAU)
			_put("s_flamingo" if _rng.randf() > 0.30 else "s_flamingo_wings",
				ff + 0.0008, 1.0, sh - _rng.randf_range(2.5, 6.0),
				_rng.randf_range(0.95, 1.15), _rng.randf() * TAU)
		ff += 0.0011
	# Stolurile isi cauta singure linia apei; malul nou e la 20-22 m de ax pe
	# 0.780-0.790, deci razele sunt mai mici si stolurile mai dese decat in
	# runda 1 (cand malul era la 35 m si banda roz se pierdea in crusta).
	# RUNDA 4 — INEL, nu discuri. Discurile de raza 13-16 m puneau cea mai mare
	# parte a pasarilor DEPARTE de linia apei, unde fereastra de cota le respinge:
	# masurat pe G_r3_hero.png, 0,39% acoperire roz cu cea mai mare pata de
	# 137 px, fata de 8,13% / 2259 px in referinta. `shore_ring` aseaza fiecare
	# pasare pe conturul lacului, deci inelul e continuu din constructie.
	# Sectoarele vin din masuratoare (`--arc`): la frac 0,770 soferul vede
	# conturul intre 5 si 282 grade, la 0,775 intre 21 si 243, la 0,780 intre
	# 41 si 186. Miezul mereu vizibil e 40-190, deci acolo pun inelul cel mai
	# dens, si intind cozi mai rare pe restul arcului vazut de la intrare.
	_ring(0.780, 1.0, 22.0, 40.0, 190.0, 2000, 0.20, 11.0, 7.0, 2.2)
	_ring(0.780, 1.0, 22.0, 186.0, 252.0, 500, 0.24, 8.0, 5.0, 2.2)
	_ring(0.780, 1.0, 22.0, 348.0, 42.0, 600, 0.24, 8.0, 5.0, 2.2)
	# Grupuri revarsate in apa mica, ca in referinta (pasari izolate dincolo de
	# inel, pe luciu): banda mutata spre apa, densitate mica.
	_ring(0.780, 1.0, 22.0, 55.0, 175.0, 420, 0.34, 17.0, -2.0, 1.3, 1.6)
	# RUNDA 6 — UMPLEREA LUCIULUI (critica bucla orba: "flamingii sunt un TIV
	# de tarm"). Inelele de mai sus (shore_ring) pun pasarile STRICT pe
	# conturul lacului: masurat raport roz/apa 0,007 fata de 0,699 in
	# referinta, banda verticala 0,128 fata de peste 0,4 — suprafata din
	# spatele inelului ramanea apa goala. `water_fill` populeaza INTERIORUL
	# poligonului `custom_lagoon`, cu densitatea scazand spre larg
	# (`water_falloff`), plus o parte in zbor jos deasupra apei
	# (`fly_fraction`) — asta ridica direct banda verticala, fiindca nu mai
	# stau toate la aceeasi inaltime de orizont ca cele de pe mal.
	_water_fill(0.780, 1.0, 22.0, 260, 2.2, 0.16)
	# Elefantii de pe crusta (referinta: trei siluete gri pe alb). DOI stau ca
	# decor, mergand spre lac; al treilea si al patrulea TRAVERSEAZA drumul
	# (HazardMarker G_Elefant1/2 in Track14.tscn). Trei hazarduri pe acelasi
	# tronson insemnau drum ocupat permanent (ProbeRace: 26% lent, doua
	# blocaje), asa ca doar doi sunt mobili.
	# Elefantii de decor stau pe crusta ALBA dintre drum si mal, la 0.762-0.771
	# - adica in fata soferului cand vine spre lac, cu apa in spatele lor
	# (compozitia din referinta: siluete gri pe alb, cu turcoazul dincolo).
	_put("s_elephant", 0.7660, 1.0, 19.0, 1.05, 1.9)
	_put("s_elephant", 0.7705, 1.0, 25.0, 1.15, 2.0)
	_put("s_elephant", 0.7620, 1.0, 30.0, 0.95, 1.7)
	_put("s_carcass_vultures", 0.7585, 1.0, 9.0, 1.15, 2.1)
	_put("s_carcass_vultures", 0.804, -1.0, 11.0, 1.0, 0.6)
	# Bolovani de granit izolati pe crusta, ca in referinta (petele gri intre
	# lac si drum): sparg albul continuu si primesc umbra lunga.
	var rocks := [
		[0.7555, 1.0, 16.0, "s_kopje_boulder_a", 0.85],
		[0.7645, 1.0, 13.0, "s_kopje_boulder_c", 0.70],
		[0.7745, 1.0, 15.0, "s_kopje_boulder_b", 0.95],
		[0.7600, -1.0, 14.0, "s_kopje_boulder_b", 0.80],
		[0.7710, -1.0, 10.0, "s_kopje_boulder_a", 0.65],
	]
	for r: Array in rocks:
		_put(r[3] as String, r[0] as float, r[1] as float, r[2] as float,
			r[4] as float, _rng.randf() * TAU)


## 0.756-0.800, STANGA: padurea Lerai — fever_tree in banda deasa, coroanele
## se ating (referinta: perete verde-galben pe o latura). Trunchiul opreste,
## coroana nu (world_prop: "trunk"), deci se poate apropia la 7,5 m de
## margine fara sa intre in banda.
func _lerai() -> void:
	var f := 0.756
	var i := 0
	while f < 0.800:
		var near := 7.5 + _rng.randf_range(0.0, 2.5)
		_put("s_fever_tree", f, -1.0, near, _rng.randf_range(0.95, 1.20),
			_rng.randf() * TAU)
		_put("s_fever_tree", f + 0.0015, -1.0, near + _rng.randf_range(7.0, 10.0),
			_rng.randf_range(1.0, 1.3), _rng.randf() * TAU)
		if i % 2 == 0:
			_put("s_fig_tree", f + 0.003, -1.0, near + _rng.randf_range(15.0, 20.0),
				_rng.randf_range(0.9, 1.15), _rng.randf() * TAU)
		if i % 3 == 1:
			_put("s_euphorbia", f + 0.002, -1.0, 6.0 + _rng.randf_range(0.0, 1.5),
				_rng.randf_range(1.0, 1.4), _rng.randf() * TAU)
		f += 0.0045
		i += 1


## 0.789-0.812: tabara balonului. Vartejul e la 7,4 m de ax la 0.802, deci
## tabara sta mai departe (11-24 m) ca sa nu se acopere reciproc. Balonul e
## 16,6 x 9,1 m culcat: pata galben-verde exact ca in referinta.
func _balloon_camp() -> void:
	# Mutata in runda 2 de la 0.791-0.798: acolo lacul nou (centru (-55,-30))
	# ajunge la 20 m de ax si tabara ar fi stat IN apa (amestec de laguna
	# 0.33-0.99 la 15-25 m). La 0.806-0.816 amestecul e 0.00 si terenul -0.30,
	# adica crusta uscata dincolo de lac - exact ca in referinta, unde balonul
	# sta pe alb, cu apa intre el si drum.
	_put("s_safari_balloon_landed", 0.8085, 1.0, 17.0, 1.0, 2.6)
	_put("s_safari_tent", 0.8115, 1.0, 13.0, 1.0, 1.1)
	_put("s_safari_tent", 0.8135, 1.0, 20.0, 0.95, 2.4)
	_put("s_land_rover", 0.8065, 1.0, 11.0, 1.0, 1.9)
	_put("s_campfire", 0.8105, 1.0, 15.5, 1.0, 0.0)
	_put("s_acacia_umbrella_b", 0.8155, 1.0, 24.0, 1.15, 0.9)
	_put("s_acacia_umbrella_a", 0.806, 1.0, 19.0, 1.05, 2.2)
	_put("s_termite_mound_a", 0.800, 1.0, 8.5, 1.2, 0.0)
	_put("s_termite_mound_b", 0.809, -1.0, 8.0, 1.1, 0.0)
	_put("s_dead_tree", 0.804, -1.0, 10.0, 1.15, 1.4)
	_put("s_acacia_umbrella_c", 0.811, -1.0, 15.0, 1.2, 0.4)


## 0.816-0.852: iesirea spre spartura. Terenul urca pe DREAPTA (masurat:
## +6,2 m la 25 m pe 0.820, +19,6 la 0.825), deci acolo merg bolovanii mari si
## coroanele inalte — se etajeaza natural. Pe stanga campia ramane plata.
func _to_gap() -> void:
	var items := [
		[0.816, 1.0, 14.0, "s_kopje_boulder_a", 1.30],
		[0.820, 1.0, 20.0, "s_kopje_boulder_b", 1.60],
		[0.824, 1.0, 16.0, "s_acacia_umbrella_a", 1.20],
		[0.828, 1.0, 22.0, "s_kopje_boulder_c", 1.40],
		[0.833, 1.0, 12.0, "s_acacia_umbrella_c", 1.05],
		[0.838, 1.0, 17.0, "s_baobab", 0.80],
		[0.844, 1.0, 11.0, "s_fever_tree", 1.00],
		[0.850, 1.0, 18.0, "s_acacia_umbrella_b", 1.15],
		[0.818, -1.0, 12.0, "s_acacia_umbrella_b", 1.10],
		[0.826, -1.0, 18.0, "s_acacia_umbrella_a", 1.25],
		[0.831, -1.0, 9.0, "s_dead_tree", 1.05],
		[0.836, -1.0, 15.0, "s_acacia_umbrella_c", 1.15],
		[0.842, -1.0, 11.0, "s_fever_tree", 0.95],
		[0.848, -1.0, 20.0, "s_acacia_umbrella_a", 1.20],
		[0.852, -1.0, 10.0, "s_euphorbia", 1.30],
	]
	for t: Array in items:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			t[4] as float, _rng.randf() * TAU)
	var mounds := [
		[0.822, -1.0, 7.0, "s_termite_mound_a"],
		[0.834, 1.0, 8.0, "s_termite_mound_b"],
		[0.846, -1.0, 7.5, "s_termite_mound_a"],
	]
	for t: Array in mounds:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			_rng.randf_range(1.0, 1.4), _rng.randf() * TAU)


# ------------------------------------------------------------------ ajutoare

## Punctul de lume la fractia `f`, `dist` metri lateral de MARGINEA benzii, pe
## partea `sgn` (+1 dreapta soferului). Cota vine din raza reala pe teren, nu
## din campul de inaltime (memoria `terrain-mesh-y-extrapoleaza`).
func _world_at(f: float, sgn: float, dist: float) -> Vector3:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var hw := _track.width_at_index(i)
	var q: Vector3 = p + s * sgn * (hw + dist)
	q.y = _sol_real(q.x, q.z)
	return q


## Degajarea (in metri de la marginea benzii) la care terenul intra sub apa pe
## fractia data, cautata din 1 in 1 m. Intoarce -1 daca nu exista apa pana la
## `dmax`. Exista fiindca lacul mutat in runda 2 NU e concentric cu drumul:
## linia apei sare de la 26 m (frac 0.775) la 20 m (0.780) la 22 m (0.790), iar
## un rand de pasari pus la o degajare FIXA cade jumatate in apa (23 de piese
## sarite de garda din `_put`) si jumatate pe crusta uscata, la 6 m de mal.
func _shore_dist(f: float, sgn: float, dmax: float) -> float:
	var d := 3.0
	while d <= dmax:
		if _world_at(f, sgn, d).y < _sea_y - 0.05:
			return d
		d += 1.0
	return -1.0


func _put(res_id: String, f: float, sgn: float, dist: float, scl: float,
		yaw: float) -> void:
	var q := _world_at(f, sgn, dist)
	if q.y < _sea_y - 0.05:
		print("; ATENTIE %s la frac %.3f (%.1f m, semn %.0f) e SUB apa (%.2f < %.2f) - sarit"
			% [res_id, f, dist, sgn, q.y, _sea_y])
		_warn += 1
		return
	_n += 1
	var b := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
	var nm := "%s_%03d" % [res_id.trim_prefix("s_"), _n]
	_out.append("")
	_out.append("[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%s\")]"
		% [nm, ZONE, res_id])
	# Transform3D se scrie pe RANDURILE bazei (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
		q.x, q.y, q.z])


## Un nod FlamingoFlock: stolul isi cauta singur linia apei in raza data, deci
## daca se muta lacul se muta si pasarile.
func _flock(f: float, sgn: float, dist: float, radius: float, count: int,
		wings: float) -> void:
	var q := _world_at(f, sgn, dist)
	_n += 1
	_out.append("")
	_out.append("[node name=\"StolFlamingi_%03d\" type=\"Node3D\" parent=\"%s\"]" % [_n, ZONE])
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)"
		% [q.x, q.y, q.z])
	_out.append("script = ExtResource(\"flock\")")
	_out.append("count = %d" % count)
	_out.append("radius = %.1f" % radius)
	_out.append("wings_fraction = %.2f" % wings)
	_out.append("seed = %d" % (1400 + _n))


## Un nod care umple INTERIORUL lacului (`FlamingoFlock.water_fill`), cu
## densitate scazand spre larg si o parte in zbor jos. Punctul de ancorare
## e doar pentru cota initiala (`_world_at` pe crusta, langa mal) — asezarea
## reala foloseste poligonul `custom_lagoon` direct in `_build_water_fill`.
func _water_fill(f: float, sgn: float, dist: float, water_count: int,
		falloff: float, fly_fraction: float) -> void:
	var q := _world_at(f, sgn, dist)
	_n += 1
	_out.append("")
	_out.append("[node name=\"LuciuFlamingi_%03d\" type=\"Node3D\" parent=\"%s\"]" % [_n, ZONE])
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)"
		% [q.x, q.y, q.z])
	# "flockg" (FlamingoFlock, scenes/props/flamingo_flock.gd), NU "flock"
	# (scenes/props/flock.gd, extends MultiMeshInstance3D — incompatibil cu
	# type="Node3D" de mai sus si nu declara water_fill/water_count/etc).
	# Bug descoperit la integrare: nodul se incarca "curat" fiindca Node3D
	# accepta orice script, dar water_fill nu exista pe flock.gd, deci
	# stolul din luciu nu se construia niciodata.
	_out.append("script = ExtResource(\"flockg\")")
	_out.append("count = 0")
	_out.append("water_fill = true")
	_out.append("water_count = %d" % water_count)
	_out.append("water_falloff = %.2f" % falloff)
	_out.append("fly_fraction = %.2f" % fly_fraction)
	_out.append("wings_fraction = 0.22")
	_out.append("seed = %d" % (1400 + _n))


## Un stol pe CONTURUL lacului (`FlamingoFlock.shore_ring`). Spre deosebire de
## `_flock`, nodul nu mai defineste un disc: el da doar punctul de ancorare
## (pentru cota), iar asezarea urmareste linia apei pe sectorul de unghi cerut.
func _ring(f: float, sgn: float, dist: float, a_from: float, a_to: float,
		count: int, wings: float, r_in: float, r_out: float, bias: float,
		depth: float = 0.6) -> void:
	var q := _world_at(f, sgn, dist)
	_n += 1
	_out.append("")
	_out.append("[node name=\"InelFlamingi_%03d\" type=\"Node3D\" parent=\"%s\"]" % [_n, ZONE])
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)"
		% [q.x, q.y, q.z])
	_out.append("script = ExtResource(\"flock\")")
	_out.append("count = %d" % count)
	_out.append("shore_ring = true")
	_out.append("arc_from_deg = %.1f" % a_from)
	_out.append("arc_to_deg = %.1f" % a_to)
	_out.append("ring_in = %.1f" % r_in)
	_out.append("ring_out = %.1f" % r_out)
	_out.append("ring_bias = %.1f" % bias)
	_out.append("wings_fraction = %.2f" % wings)
	_out.append("depth_max = %.2f" % depth)
	_out.append("seed = %d" % (1400 + _n))
