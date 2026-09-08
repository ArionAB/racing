@tool
class_name FlamingoFlock
extends Node3D
## STOL DE FLAMINGI pe malul lacului de soda (Serengeti, POI G — brief §2 E/G,
## §5 „flamingo.glb / flamingo_wings.glb"). Decor static: UN MultiMesh per
## GLB, in loc de sute de noduri (fiecare nod = un desen; stolul de 150 ar fi
## fost 150 de draw call-uri pentru 1,2 m de pasare la 40 m).
##
## Pasarile se aseaza SINGURE pe linia apei, la rulare: se cauta puncte in
## jurul nodului (raza `radius`) a caror cota de teren e intr-o fereastra fata
## de nivelul apei (`depth_min..depth_max` sub apa = in apa mica, pana la
## `crust_max` peste apa = pe crusta), deci nodul se trage pe mal si stolul isi
## gaseste linia — daca se muta lacul, se muta si flamingii, fara sa ramana
## pasari pe uscat sau in adanc (memoria `terrain-mesh-y-extrapoleaza`: cota
## se ia cu RAZA pe TerrainBody, nu din camp).
##
## Materialul e atlasul comun (`Palette.world_material`), deci stolul nu aduce
## niciun material in plus (garda din tools/probe_decor.gd). Coliziune: niciuna
## (flamingii sunt fantome, ca in `WorldProp.PROP_COLLISION`).

const GLB_STAND := "res://assets/models/serengeti/plants/flamingo.glb"
const GLB_WINGS := "res://assets/models/serengeti/plants/flamingo_wings.glb"

## Cate pasari, in total (stand + cu aripile deschise).
@export_range(1, 600, 1) var count: int = 120
## Raza (m) in jurul nodului in care se cauta linia apei.
@export_range(5.0, 200.0, 1.0) var radius: float = 40.0
## Fereastra de cota fata de apa in care sta o pasare: de la `depth_max` sub
## apa (apa mica, picioarele in apa) pana la `crust_max` peste apa (pe crusta).
@export_range(0.0, 3.0, 0.05) var depth_max: float = 0.6
@export_range(0.0, 8.0, 0.05) var crust_max: float = 2.6
## Fractia cu aripile deschise (a doua stare din kit).
@export_range(0.0, 1.0, 0.05) var wings_fraction: float = 0.25
## Samanta: aceeasi asezare la fiecare rulare (capturile trebuie sa fie
## comparabile intre runde).
@export var seed: int = 1407
## INEL PE LINIA APEI (runda 4). Cu `shore_ring` pornit, pasarile nu se mai
## imprastie intr-un DISC in jurul nodului, ci se aseaza pe CONTURUL lacului:
## se merge de-a lungul poligonului `custom_lagoon` si se pune cate o pasare
## intr-o banda ingusta de o parte si de alta a liniei apei. Motivul e masurat,
## nu estetic: un disc de raza 13-16 m are cea mai mare parte a ariei DEPARTE
## de linia apei, iar fereastra de cota respinge acolo, deci din 210 pasari
## cerute treceau cateva zeci, imprastiate — 0,39% acoperire roz in cadru, cu
## cea mai mare pata de 137 px, fata de 8,13% / 2259 px in referinta. Un inel
## pune fiecare pasare pe linie din constructie, deci silueta iese CONTINUA.
@export var shore_ring: bool = false
## Cat din perimetrul lacului acopera stolul: unghiul de start si cel de final
## (grade, in jurul centrului lacului, masurate in planul XZ cu atan2(z, x)).
@export var arc_from_deg: float = 0.0
@export var arc_to_deg: float = 360.0
## Latimea benzii inelului: cat spre apa (`ring_in`) si cat spre crusta
## (`ring_out`) fata de linia apei, in metri.
@export_range(0.5, 30.0, 0.5) var ring_in: float = 5.0
@export_range(-10.0, 30.0, 0.5) var ring_out: float = 3.0
## Cat de tare se ingramadesc spre linia apei: 1 = uniform pe banda, 3 = mult
## mai dese la mal (ca in referinta, unde inelul e lipit de apa).
@export_range(1.0, 6.0, 0.1) var ring_bias: float = 2.6

var placed: int = 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Terenul e construit de parintele Track in _ready-ul LUI, care vine DUPA
	# al copiilor; corpul de coliziune ajunge in serverul de fizica un cadru
	# mai tarziu. Deci: doua cadre de proces + doua de fizica, apoi razele.
	_build.call_deferred()


func _build() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var track := _find_track()
	if track == null:
		push_warning("FlamingoFlock %s: nu e sub o pista, nimic de asezat" % name)
		return
	var sea_y: float = track._sampler.mean_road_y() + track.sea_level_offset
	# REMAPUL DE SLOTURI TREBUIE FACUT AICI. `WorldProp` il aplica doar
	# prop-urilor instantiate ca noduri, iar stolul deseneaza un MultiMesh
	# construit direct din GLB — deci pasarile ieseau cu UV-urile brute pe
	# slotul 31, care NU exista in atlas: magenta fluorescent, masurat pe
	# captura din runda 4. Folosim exact aceeasi tabela ca prop-urile
	# (`WorldProp.SLOT_REMAP_BY_MODEL`), ca pasarile din stol si cele asezate
	# ca noduri sa aiba aceeasi culoare.
	var stand_mesh := HerdHazard._animal_mesh_from(GLB_STAND)
	var wings_mesh := HerdHazard._animal_mesh_from(GLB_WINGS)
	var remap_stand: Dictionary = WorldProp.SLOT_REMAP_BY_MODEL.get("flamingo", {})
	var remap_wings: Dictionary = WorldProp.SLOT_REMAP_BY_MODEL.get("flamingo_wings", {})
	if stand_mesh != null and not remap_stand.is_empty():
		stand_mesh = WorldProp._mesh_with_slots_moved(stand_mesh, remap_stand)
	if wings_mesh != null and not remap_wings.is_empty():
		wings_mesh = WorldProp._mesh_with_slots_moved(wings_mesh, remap_wings)
	if stand_mesh == null:
		push_warning("FlamingoFlock: %s nu se incarca" % GLB_STAND)
		return
	if wings_mesh == null:
		wings_mesh = stand_mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var stand_xf: Array[Transform3D] = []
	var wings_xf: Array[Transform3D] = []
	var space := get_world_3d().direct_space_state
	var origin := global_position
	var tries := 0
	var ring: PackedVector2Array = _ring_line(track) if shore_ring else PackedVector2Array()
	if shore_ring and ring.size() < 2:
		push_warning("FlamingoFlock %s: shore_ring fara contur de lac; revin la disc" % name)
	while stand_xf.size() + wings_xf.size() < count and tries < count * 40:
		tries += 1
		var x := 0.0
		var z := 0.0
		if ring.size() >= 2:
			# Un punct pe linia apei, plus o abatere perpendiculara pe banda.
			var t := rng.randf() * float(ring.size() - 1)
			var i0 := int(t)
			var fr := t - float(i0)
			var p0 := ring[i0]
			var p1 := ring[mini(i0 + 1, ring.size() - 1)]
			var pt := p0.lerp(p1, fr)
			var tang := (p1 - p0)
			var nrm := Vector2(1.0, 0.0)
			if tang.length() > 0.001:
				nrm = Vector2(-tang.y, tang.x).normalized()
			# `u` in [0,1) impins spre 0 de `ring_bias` => mai dese la mal.
			var u := pow(rng.randf(), ring_bias)
			var off := u * (ring_in if rng.randf() < 0.5 else -ring_out)
			# Normala poligonului poate arata spre apa sau spre uscat, in
			# functie de sensul de parcurgere; `_ring_line` o orienteaza deja
			# spre EXTERIOR, deci +off e crusta si -off e apa.
			var q2 := pt + nrm * off
			x = q2.x
			z = q2.y
		else:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * radius
			x = origin.x + cos(a) * r
			z = origin.z + sin(a) * r
		var g := _ground(space, x, z, track)
		if is_nan(g):
			continue
		var rel := g - sea_y
		if rel < -depth_max or rel > crust_max:
			continue
		# Cu picioarele in apa pasarea sta pe FUND, nu pe suprafata: corpul
		# (1,27 m) ramane oricum deasupra apei de 0,6 m.
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(0.9, 1.1)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
		# In apa mica pasarea sta pe FUND, dar corpul (1,27 m) trebuie sa
		# ramana deasupra suprafetei ca sa se vada: sub apa se ridica la
		# linia apei, ca picioarele sa fie ce se scufunda, nu tot corpul.
		var xf := Transform3D(basis, Vector3(x, maxf(g, sea_y - 0.15), z))
		if rng.randf() < wings_fraction:
			wings_xf.append(xf)
		else:
			stand_xf.append(xf)
	placed = stand_xf.size() + wings_xf.size()
	if placed == 0:
		push_warning("FlamingoFlock %s: niciun punct pe linia apei in raza de %.0f m (apa la %.2f)"
			% [name, radius, sea_y])
		return
	_make_lot("Stand", stand_mesh, stand_xf)
	_make_lot("Wings", wings_mesh, wings_xf)
	if OS.is_stdout_verbose() or "--flock-report" in OS.get_cmdline_user_args():
		print("FlamingoFlock %s: %d pasari (%d cu aripi) din %d incercari, apa la %.2f"
			% [name, placed, wings_xf.size(), tries, sea_y])


func _make_lot(lot_name: String, mesh: Mesh, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	# ATENTIE la verificare: `get_instance_transform` NU e de incredere in
	# `--headless` — o sonda minimala (tools/ProbeMM.tscn) scrie o transformare
	# intr-un MultiMesh proaspat si o citeste inapoi ca (0,0,0) in toate cele
	# trei ordini de configurare. Deci „citit inapoi zero" NU dovedeste ca
	# scrierea s-a pierdut, si o sonda care numara pozitii headless minte.
	# Verificarea corecta a inelului e captura, plus numarul din --flock-report.
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = lot_name
	mmi.multimesh = mm
	# Transformurile sunt in spatiul LUMII (razele au dat cote de lume), deci
	# nodul nu trebuie sa le mai mute o data — aceeasi capcana ca la turma.
	mmi.top_level = true
	mmi.transform = Transform3D.IDENTITY
	mmi.material_override = Palette.world_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)


## Cota solului dintr-o raza pe TerrainBody; NAN daca nu exista teren acolo.
func _ground(space: PhysicsDirectSpaceState3D, x: float, z: float,
		track: Track) -> float:
	var top := global_position.y + 120.0
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, top, z), Vector3(x, top - 400.0, z))
	q.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and guard < 8:
		var col := hit["collider"] as Node
		if col != null and col.name == "TerrainBody":
			return float(hit["position"].y)
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if track._sampler != null:
		return track._sampler.ground_y(x, z)
	return NAN


func _find_track() -> Track:
	var n := get_parent()
	while n != null:
		if n is Track:
			return n as Track
		n = n.get_parent()
	return null


## Conturul lacului (poligonul `custom_lagoon` al pistei), reesantionat des si
## taiat pe sectorul de unghi cerut, cu punctele in ORDINE ca sa formeze o
## linie continua. Sensul e normalizat astfel incat normala (-y, x) a fiecarui
## segment sa arate spre EXTERIORUL lacului (spre crusta), ca semnul abaterii
## din `_build` sa insemne acelasi lucru indiferent cum e scris poligonul.
func _ring_line(track: Track) -> PackedVector2Array:
	var poly: PackedVector2Array = track._lagoon_poly()
	if poly.size() < 3:
		return PackedVector2Array()
	# Centrul si sensul de parcurgere: aria cu semn spune daca poligonul e scris
	# in sens trigonometric sau orar.
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	var area := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		area += a.x * b.y - b.x * a.y
	var pts := PackedVector2Array(poly)
	if area > 0.0:
		# Sens trigonometric: normala (-y, x) arata spre INTERIOR, deci inversam
		# parcurgerea ca sa arate spre crusta.
		pts.reverse()
	# Reesantionare deasa (~1 m), ca banda sa fie neteda si densitatea uniforma
	# pe toata lungimea, nu concentrata in cele 16 varfuri ale poligonului.
	var dense := PackedVector2Array()
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var steps := maxi(1, int(a.distance_to(b)))
		for k in steps:
			dense.append(a.lerp(b, float(k) / float(steps)))
	dense.append(dense[0])
	# Taierea pe sector de unghi: pastram doar punctele din arcul cerut, in
	# ordinea in care apar pe contur.
	var lo := fposmod(arc_from_deg, 360.0)
	var hi := fposmod(arc_to_deg, 360.0)
	if is_equal_approx(lo, hi):
		return dense
	var out := PackedVector2Array()
	for p in dense:
		var ang := fposmod(rad_to_deg(atan2(p.y - c.y, p.x - c.x)), 360.0)
		var inside := (ang >= lo and ang <= hi) if lo < hi else (ang >= lo or ang <= hi)
		if inside:
			out.append(p)
	return out
