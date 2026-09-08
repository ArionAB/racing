extends Node
## Generator de decor MANUAL pentru POI B — RAUL DE GNU (Track14 Serengeti,
## frac 0.040-0.121, traversarea turmei la 0.075). Nu e sonda: CALCULEAZA
## transformarile care se lipesc in Track14.tscn sub
## `DecorManual/ZoneB_RaulDeGnu`, cu cotele citite din terenul real.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerB.tscn
##
## Ce decide compozitia, si de ce cifrele sunt astea (toate masurate aici, in
## rulare — vezi liniile `;` din iesire):
##
## 1. DRUMUL E DREPT PE z = 165, de la x = 230 (start) la x = -70, si masina
##    merge spre -x. `_side_at` = dir x UP = -z, deci side_sign +1 e DREAPTA
##    soferului (z < 165) si -1 e STANGA (z > 165). La 40-50 m in dreapta
##    trece DRUMUL DE INTOARCERE (z ~ 113-127, frac 0.90-0.95), iar dincolo
##    de el urca flancul craterului (TerrainPeak la (95, 44, 75), raza 45).
##    Consecinta: campia larga e pe STANGA; acolo sta turma de fundal si
##    kopje-ul, iar pe dreapta decorul se opreste inainte de drumul de
##    intoarcere (garda `_road_clear`: nicio piesa pe NICIUN carosabil, nu
##    doar pe cel din fata).
##
## 2. TRAVERSAREA e la x = 70 (frac 0.076, masurat cu ProbeFrac), culoar de
##    24 m (x 58-82), curgere pe +z de la z = 116 la z = 214 (loop_len =
##    15 s x 6,5 m/s = 97,5 m). Pe fasia asta copacii de langa banda ar sta
##    IN turma; nu-i scoatem (in referinta turma curge printre acacii), dar
##    ii tinem la 8-14 m de muchie, ca trunchiul sa nu fie pe axa culoarului
##    si coroana sa atarne PESTE animale.
##
## 3. FRUSTUMUL (brief §2.0): la d metri de ax se vede in sus 10 + 0,093 d.
##    O acacie de 7-10 m la 3-6 m de muchie e la ~12-14 m de ax => plafon
##    11,1-11,3 m: coroana intra intreaga, si umbra ei cade pe drum. Asta e
##    „identitatea" din brief, deci randul de langa banda e des (un copac la
##    ~13 m pe fiecare parte, decalat cu o jumatate de pas intre parti), cu
##    coroane care se ating pe alocuri, ca in referinta.
##
## 4. ETAJE. Referinta are trei: prim-plan (copaci mari la 2-8 m, termitiere,
##    bolovani), mediu (kopje de granit + acacii la 30-60 m), fundal (turma ca
##    masa, copaci mici in ceata). Vederea de sus minte despre densitate
##    (memoria `driver-view-for-composition`): fiecare etaj se verifica pe
##    captura --gamecam la 0.06, nu pe harta.
##
## 5. SOARELE se citeste din DirectionalLight3D dupa build, nu din euler:
##    generatorul tipareste directia umbrei pe XZ si dot-ul cu `side`, ca sa
##    se stie pe ce parte cad umbrele acaciilor peste drum.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneB_RaulDeGnu"
const KIT := "res://assets/models/serengeti/"

## Intervalul POI-ului (brief-ul bucatii B).
const F0: float = 0.040
const F1: float = 0.121
## Culoarul turmei pe x (nodul RaulDeGnu la x = 70, corridor_m 24).
const HERD_X0: float = 58.0
const HERD_X1: float = 82.0

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _rng := RandomNumberGenerator.new()
## Raza la baza si inaltimea fiecarei piese, MASURATE din GLB la pornire
## (Track.model_aabb), nu scrise de mana.
var _base_r := {}
var _height := {}


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_rng.seed = 140302
	_measure_kit()
	_report_sun()
	_report_route()
	_roadside_acacias()
	_bushes()
	_grass_tufts()
	_termites()
	_boulders_and_kopje()
	_mid_acacias()
	_backdrop()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese, %d avertismente" % [_n, _warn])
	get_tree().quit(0)


func _measure_kit() -> void:
	for m in ["plants/acacia_umbrella_a", "plants/acacia_umbrella_b",
			"plants/acacia_umbrella_c", "plants/euphorbia", "plants/dead_tree",
			"plants/tropical_shrub",
			"plants/grass_tuft_large", "plants/grass_tuft_small",
			"rocks/termite_mound_a", "rocks/termite_mound_b",
			"rocks/kopje_boulder_a", "rocks/kopje_boulder_b", "rocks/kopje_boulder_c"]:
		var ps := load(KIT + m + ".glb") as PackedScene
		var root := ps.instantiate() as Node3D
		var box := Track.model_aabb(root)
		root.free()
		_base_r[m] = 0.5 * maxf(box.size.x, box.size.z)
		_height[m] = box.size.y
		print("; kit %-26s baza r=%.2f  h=%.2f  y0=%.2f" % [m, _base_r[m], _height[m], box.position.y])


func _report_sun() -> void:
	var sun: DirectionalLight3D = null
	for c in _track.get_children():
		if c is DirectionalLight3D:
			sun = c
	if sun == null:
		print("; ATENTIE fara DirectionalLight3D")
		return
	var d := -sun.global_transform.basis.z
	var i := int(0.06 * float(_track.baked.size()))
	var s := _track._side_at(i)
	print("; soare: directia luminii (%.2f, %.2f, %.2f); umbra pe XZ -> (%.2f, %.2f); dot(side, umbra)=%.2f (>0: umbra cade spre DREAPTA soferului)"
		% [d.x, d.y, d.z, d.x, d.z, s.x * d.x + s.z * d.z])


func _report_route() -> void:
	var n := _track.baked.size()
	for f in [0.040, 0.045, 0.06, 0.066, 0.076, 0.086, 0.10, 0.121]:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		print("; frac %.3f: ax=(%.1f, %.2f, %.1f) half=%.1f side=(%.1f, %.1f) sol=%.2f"
			% [f, p.x, p.y, p.z, _track.width_at_index(i), _track._side_at(i).x,
			_track._side_at(i).z, _sol_real(p.x, p.z)])


# ------------------------------------------------------------------ compozitia

## Randul de acacii-umbrela de langa banda, pe ambele parti.
func _roadside_acacias() -> void:
	var models: Array[String] = [
		"plants/acacia_umbrella_a", "plants/acacia_umbrella_b",
		"plants/acacia_umbrella_a", "plants/acacia_umbrella_c",
		"plants/acacia_umbrella_b", "plants/acacia_umbrella_a",
		"plants/acacia_umbrella_b", "plants/acacia_umbrella_c",
	]
	# Runda 1b: cu pasul de 11 m (0.0052) jumatatea de jos a cadrului la 0.06
	# era goala — in referinta coroanele se ating si intra din colturile
	# cadrului. Pas de 8,4 m, muchia la 2,5-5,5 m.
	var step := 0.0040
	var k := 0
	for sgn in [1.0, -1.0]:
		var f := F0 + (0.0 if sgn > 0.0 else 0.5 * step)
		while f < F1:
			var x := _x_at(f)
			var in_herd := x > HERD_X0 - 6.0 and x < HERD_X1 + 6.0
			var gap := _rng.randf_range(8.0, 14.0) if in_herd else _rng.randf_range(2.5, 5.5)
			var mdl := models[k % models.size()]
			_place(mdl, "acacie", f, sgn, gap, _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.95, 1.15), "trunk")
			k += 1
			f += step * _rng.randf_range(0.85, 1.15)


## Etajul de la inaltimea rotii, RUNDA 2. In runda 1 era un rand continuu de
## `tropical_shrub` de la 1 la 4,5 m pe ambele parti, la ~4,5 m unul de altul:
## pe captura de la volan iesea un GARD verde neintrerupt intre banda si turma,
## exact acolo unde referinta are SOL de savana (iarba aurie joasa, pete de
## pamant, termitiere, o acacie izolata). Verdictul criticului, cuvant cu
## cuvant: „animalele nu stau PE un camp, ci apar peste o bordura verde".
##
## Reparatia are doua jumatati, si a doua e cea care conteaza:
##   (a) tufele ies COMPLET din banda 2-6 m si se raresc la ~1/3 (pasul urca
##       de la 0.0022 la 0.0068, adica de la ~4,6 m la ~14 m; ele raman doar
##       de la 6 m in sus, ca etaj care leaga solul de coroane);
##   (b) banda 1,5-6 m se umple cu SMOCURI de iarba aurie — `grass_tuft_large`
##       (1,20 m) si `grass_tuft_small` (0,62 m), remapate pe slotul 13
##       DRY_VEGETATION in `world_prop.SLOT_REMAP_BY_MODEL` (masurat: veneau pe
##       7 KERB_RED si 8 CONCRETE). Sub 1,2 m nu ascund nimic, dar rup planul
##       de iarba in smocuri, ca in referinta.
## Amandoua clasele exista deja pe alte piste => zero materiale in plus.
func _bushes() -> void:
	for sgn in [1.0, -1.0]:
		var f := F0 + (0.0034 if sgn > 0.0 else 0.0)
		while f < F1:
			var x := _x_at(f)
			var in_herd := x > HERD_X0 - 4.0 and x < HERD_X1 + 4.0
			var gap := _rng.randf_range(9.0, 16.0) if in_herd else _rng.randf_range(6.0, 13.0)
			_place("plants/tropical_shrub", "tufa", f, sgn, gap,
				_rng.randf_range(0.0, TAU), _rng.randf_range(1.2, 2.0), "none")
			f += 0.0068 * _rng.randf_range(0.8, 1.2)


## Smocurile de iarba aurie din banda de la muchie (1,5-6 m), dense: pasul de
## 0.0011 pe frac ~ 2,3 m, plus un al doilea smoc din trei la 5-9 m. Sunt
## piesa care inlocuieste gardul de tufe, deci trebuie sa fie MULTE si JOASE.
## Culoarul turmei ramane liber ca inainte (nu punem iarba unde calca 620 de
## animale — ar iesi smocuri prin picioarele lor).
func _grass_tufts() -> void:
	for sgn in [1.0, -1.0]:
		var f := F0 + (0.0006 if sgn > 0.0 else 0.0)
		var j := 0
		while f < F1:
			var x := _x_at(f)
			var in_herd := x > HERD_X0 - 3.0 and x < HERD_X1 + 3.0
			if not in_herd:
				var big := j % 3 != 2
				var mdl := "plants/grass_tuft_large" if big else "plants/grass_tuft_small"
				_place(mdl, "smoc", f, sgn, _rng.randf_range(1.5, 6.0),
					_rng.randf_range(0.0, TAU),
					_rng.randf_range(1.1, 1.9) if big else _rng.randf_range(1.4, 2.4), "none")
				if j % 3 == 0:
					_place("plants/grass_tuft_small", "smoc", f + 0.0004, sgn,
						_rng.randf_range(5.0, 9.0), _rng.randf_range(0.0, TAU),
						_rng.randf_range(1.3, 2.2), "none")
			j += 1
			f += 0.0011 * _rng.randf_range(0.8, 1.2)


## Termitiere rosii la 2,5-5 m de muchie, alternand partile.
func _termites() -> void:
	var f := F0 + 0.0025
	var j := 0
	while f < F1:
		var sgn := 1.0 if j % 2 == 0 else -1.0
		var mdl := "rocks/termite_mound_b" if j % 3 == 1 else "rocks/termite_mound_a"
		_place(mdl, "termitiera", f, sgn, _rng.randf_range(2.5, 5.0),
			_rng.randf_range(0.0, TAU), _rng.randf_range(1.0, 1.35), "hull")
		j += 1
		f += 0.0068 * _rng.randf_range(0.8, 1.2)


## Bolovani de granit pe alocuri + KOPJE-ul de la mijlocul cadrului.
func _boulders_and_kopje() -> void:
	var f := F0 + 0.006
	var j := 0
	while f < F1:
		var sgn := -1.0 if j % 2 == 0 else 1.0
		var mdl := "rocks/kopje_boulder_b" if j % 3 == 2 else "rocks/kopje_boulder_a"
		_place(mdl, "bolovan", f, sgn, _rng.randf_range(6.0, 18.0),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.9, 1.3), "hull")
		j += 1
		f += 0.0135 * _rng.randf_range(0.8, 1.2)
	# KOPJE: in referinta e un bloc de granit la stanga, la mijlocul
	# adancimii, cu copaci pe el. La 40 m de muchie plafonul e 10 + 0,093*51
	# ~ 14,7 m, deci trei boulder_c (6 m) scalate la 1,3-1,5 + doi b + doi a
	# fac o gramada de ~9 m care intra intreaga in cadru de la 0.06 (x ~ 104;
	# kopje-ul la x ~ 30, adica 74 m in fata, 46 m la stanga).
	# Runda 1, captura: la 38-42 m de muchie si scara 1,3-1,5 kopje-ul era o
	# pata gri de 40 px in spatele coroanelor. Vine la 24-30 m si creste la
	# 1,8-2,1 (boulder_c 4,3 m -> 7,8-9,1 m); plafonul la 40 m de ax e 13,7.
	var kf := 0.0925
	_place("rocks/kopje_boulder_c", "kopje", kf, -1.0, 26.0, 0.4, 2.1, "hull")
	_place("rocks/kopje_boulder_c", "kopje", kf + 0.0030, -1.0, 29.0, 2.1, 1.8, "hull")
	_place("rocks/kopje_boulder_c", "kopje", kf - 0.0026, -1.0, 30.0, 3.6, 1.9, "hull")
	_place("rocks/kopje_boulder_b", "kopje", kf + 0.0050, -1.0, 24.0, 1.0, 1.6, "hull")
	_place("rocks/kopje_boulder_b", "kopje", kf - 0.0048, -1.0, 25.5, 5.0, 1.5, "hull")
	_place("rocks/kopje_boulder_a", "kopje", kf + 0.0012, -1.0, 21.5, 0.0, 1.5, "hull")
	_place("rocks/kopje_boulder_a", "kopje", kf - 0.0065, -1.0, 28.0, 2.5, 1.3, "hull")
	_place("plants/acacia_umbrella_b", "kopjeAcacie", kf + 0.0072, -1.0, 27.0, 1.2, 1.1, "trunk")
	_place("plants/dead_tree", "kopjeUscat", kf - 0.0080, -1.0, 24.0, 0.7, 1.1, "trunk")
	# Termitiere MARI in etajul mediu (8-14 m de muchie, 5-6,5 m inalte):
	# in referinta sunt turnurile rosii care marcheaza adancimea la 30-60 m,
	# vizibile peste tufe si sub coroane (plafon la 20 m de ax: 11,9 m).
	_place("rocks/termite_mound_b", "termitieraMare", 0.058, -1.0, 9.0, 0.8, 2.0, "hull")
	_place("rocks/termite_mound_b", "termitieraMare", 0.082, 1.0, 9.0, 2.0, 2.1, "hull")
	_place("rocks/termite_mound_b", "termitieraMare", 0.090, -1.0, 13.0, 0.3, 1.9, "hull")
	_place("rocks/termite_mound_b", "termitieraMare", 0.100, 1.0, 8.0, 1.4, 2.2, "hull")
	_place("rocks/termite_mound_b", "termitieraMare", 0.112, -1.0, 11.0, 2.6, 2.0, "hull")
	# Euphorbii candelabru (4 m) si un copac uscat: variatie de silueta la
	# inaltimea ochiului, intre termitiere si coroane.
	_place("plants/euphorbia", "euforbie", 0.0475, 1.0, 6.5, 1.0, 1.0, "trunk")
	_place("plants/euphorbia", "euforbie", 0.0895, -1.0, 7.0, 2.2, 1.1, "trunk")
	_place("plants/euphorbia", "euforbie", 0.1125, 1.0, 5.5, 0.3, 0.95, "trunk")
	_place("plants/dead_tree", "uscat", 0.0565, -1.0, 9.0, 1.5, 1.0, "trunk")
	_place("plants/dead_tree", "uscat", 0.1075, 1.0, 8.0, 4.0, 1.15, "trunk")


## Etajul MEDIU: acacii la 15-50 m de muchie pe stanga (campia larga), si
## intre cele doua drumuri pe dreapta (12-22 m, garda de carosabil decide).
func _mid_acacias() -> void:
	var models: Array[String] = ["plants/acacia_umbrella_b", "plants/acacia_umbrella_c",
		"plants/acacia_umbrella_a"]
	var f := F0 + 0.002
	var j := 0
	while f < F1 + 0.01:
		var mdl := models[j % models.size()]
		_place(mdl, "acacieMediu", f, -1.0, _rng.randf_range(15.0, 50.0),
			_rng.randf_range(0.0, TAU), _rng.randf_range(1.0, 1.2), "trunk")
		if j % 2 == 0:
			_place(models[(j + 1) % models.size()], "acacieMediu", f + 0.004, 1.0,
				_rng.randf_range(12.0, 22.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.95, 1.1), "trunk")
		j += 1
		f += 0.009 * _rng.randf_range(0.8, 1.2)


## Turma de fundal: nod cu script (HerdBackdrop), pe axa culoarului.
func _backdrop() -> void:
	var g := _sol_real(70.0, 165.0)
	_out.append('[node name="TurmaFundal" type="Node3D" parent="%s"]' % ZONE)
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 70, %f, 165)" % g)
	_out.append('script = ExtResource("herdbg")')
	_out.append("count = 420")
	_out.append("half_x = 70.0")
	_out.append("band_near = 34.0")
	_out.append("band_far = 125.0")
	_out.append("")


# ------------------------------------------------------------------ asezarea

func _x_at(frac: float) -> float:
	var n := _track.baked.size()
	return _track.baked[int(frac * float(n)) % n].x


## Distanta minima de la punct la ORICE punct copt al buclei (si drumul de
## intoarcere). O piesa pe carosabil nu se vede din generator decat asa.
func _road_clear(q: Vector3) -> float:
	var best := INF
	var n := _track.baked.size()
	for i in n:
		var p := _track.baked[i]
		var dx := p.x - q.x
		var dz := p.z - q.z
		var d := sqrt(dx * dx + dz * dz) - _track.width_at_index(i)
		best = minf(best, d)
	return best


func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull") -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = float(_base_r.get(model, 0.6)) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	var clear := _road_clear(q)
	if clear < r + 0.5:
		_warn += 1
		print("; ATENTIE %s la frac %.4f (%.1f, %.1f): marginea la %.2f m de un carosabil — SARIT"
			% [model, frac, q.x, q.z, clear - r])
		return
	if p.y - g > 1.2 or g - p.y > 1.2:
		print("; nota %s la frac %.4f: teren la %.2f m fata de sosea" % [model, frac, g - p.y])
	var h: float = float(_height.get(model, 1.0)) * scl
	var ceiling := 10.0 + 0.093 * d
	if h > ceiling + 0.5 and gap < 8.0:
		print("; nota %s la frac %.4f: %.1f m inalt la %.1f m de ax, plafon %.1f (varful iese din cadru de aproape)"
			% [model, frac, h, d, ceiling])
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	var stem := model.get_file()
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("s_%s")]'
		% [base, _n, ZONE, stem])
	# Randurile bazei (memoria `tscn-transform-e-pe-randuri`): yaw pur =
	# (c, 0, s / 0, 1, 0 / -s, 0, c) pe coloane => pe randuri (c, 0, -s, 0, 1, 0, s, 0, c).
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## Cota SOLULUI din coliziunea reala a panzei de teren (vezi
## gen_decor_capp_a.gd `_sol_real` si memoria `terrain-mesh-y-extrapoleaza`).
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
	return _sampler.ground_y(x, z)
