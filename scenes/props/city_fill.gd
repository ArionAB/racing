extends Node3D
class_name CityFill
## UMPLUTURA DE ORAS: sute de case asezate pe terenul din INTERIORUL buclei,
## desenate ca MultiMesh feliat pe celule (Jodhpur, Track17 — orasul albastru
## pe care il vezi de pe bastion, brief §2.0/§5.6 „casele din spate, dincolo de
## 40 m de drum, sunt MultiMesh feliat pe zone").
##
## De ce nu noduri in .tscn: peste ~1000 de piese, nodurile de scena blocheaza
## incarcarea (memoria `decor-in-masa-cere-multimesh`: 5633 de noduri = 25 min
## la „incarc pista"). De ce nu `FlockProp`: stolul ia UN mesh si UN material,
## iar o casa are peretele pe o clasa (varul albastru) si restul pe atlas.
## De ce nu `TrackDecorBatch` direct pe noduri instantiate: ar insemna sute de
## instantieri GLB la fiecare incarcare doar ca sa fie aruncate.
##
## Ce REFOLOSESTE: materialele vin din `WorldProp` (acelasi `_split_shutters`,
## `CLASSES_BY_MODEL`, metadata `indigo`), aplicat pe UN SABLON per (model,
## tenta) — deci o casa din umplutura arata exact ca aceeasi casa pusa de mana
## in DecorManual, si orice schimbare de clasa se propaga singura. Feliile sunt
## ideea din `TrackDecorBatch` (un MultiMesh intreg pe pista se deseneaza mereu,
## deci culling-ul moare): celule de `cell_m`.
##
## Pe fiecare model: UN mesh de perete (clasa, tenta deschisa sau indigo) si UN
## mesh de atlas (usi, balustrade, geamuri, accentele rupte — toate pe
## materialul lumii, deci unite intr-un singur ArrayMesh). Pe celula: cel mult
## 3 buffere pe model.
##
## Pozitiile se genereaza la rulare, pe TERENUL REAL (raycast pe TerrainBody,
## nu sampler-ul neted — memoria `terrain-mesh-y-extrapoleaza`), deci se mut
## singure cand se redeseneaza traseul (memoria `flockprop-snap-si-ordinea-ready`:
## listele scrise in .tscn nu afla ca terenul s-a resapat). Determinist: acelasi
## `seed_value` + acelasi teren = aceleasi case.
##
## Fara coliziune: cea mai apropiata casa e la `min_road_m` de axul oricarei
## benzi (implicit 40 m). Primul rand, langa drum, e al DecorManual (cu corpuri).
##
## `--indigo=0.4` pe linia de comanda suprascrie `indigo_ratio` (unealta de
## captura pentru amestecul de tente, punctul 3d al fundatiei).

## Casele din care se trage (ponderi in `weights`, aceeasi ordine).
@export var models: Array[PackedScene] = []
@export var weights: PackedFloat32Array = PackedFloat32Array()
## Fractia de case pe INDIGO (`blue_lime_indigo`), restul pe albastru deschis.
## Decizia de amestec e a dezvoltatorului (vezi raportul fundatiei, 3d).
@export_range(0.0, 1.0, 0.01) var indigo_ratio: float = 0.4
## Pasul grilei (m). Casele au 6,3-7,7 m latura; la 10 m raman ulite de ~2,5 m.
@export var spacing_m: float = 10.0
@export var jitter_m: float = 1.0
## Distanta minima de la axul ORICAREI benzi (bucla + scurtaturi).
@export var min_road_m: float = 40.0
## Diferenta maxima de teren sub amprenta (m); peste = panta de stanca, fara casa.
@export var max_step_m: float = 2.5
## Cat se ingroapa baza sub cel mai JOS colt (m), ca nicio casa sa nu pluteasca.
@export var sink_m: float = 0.3
## Latura celulei de feliere (m).
## 250 m, masurat de TrackDecorBatch pe Dunele (curba de draw calls se
## aplatizeaza la 250; sub, fiecare celula in plus e un buffer in plus pe model).
@export var cell_m: float = 250.0
## DISTANTA DE TAIERE a fiecarei felii (m, de la camera la centrul caselor din
## felie; 0 = oprit, comportamentul dinainte). Kyoto, nov 2026: pe telefon
## umplutura de case ducea dreapta de start de la 60 la 30 fps, desi adauga doar
## ~100k triunghiuri. Pe desktop la aspectul telefonului (ProbePerf, 0.85-0.97)
## casele triplau timpul GPU: 0,31-0,41 ms fara ele, 0,76-1,43 cu ele. Felii
## de 125 m + taiere la 260 m: 0,43-0,79. Felia mare trimitea si casele din
## spatele camerei; taierea scoate cartierele din ceata. Cu felii de 125 m cea
## mai apropiata casa care poate disparea e la ~170 m (ceata Kyoto incepe la 100).
## Masurat si: material simplu pe case = zero castig; fara umbra aruncata =
## ~o treime din cost, dar casele par lipite pe sol — nu s-a facut.
@export var visibility_end_m: float = 0.0
## Genereaza LOD-uri pe mesh-urile sabloanelor (peretele rupt si atlasul unit
## sunt ArrayMesh-uri NOI, fara LOD-urile importului). Godot alege LOD-ul unui
## MultiMesh dupa AABB-ul lui, deci celulele departate coboara singure.
@export var generate_lods: bool = true
## UMBRA DINTR-O BUCATA: fiecare model arunca umbra printr-un singur mesh
## unit (toate partile lui, doar pentru pasa de umbra), iar partile vizibile
## nu mai arunca. O casa e 4-7 parti (clasele de material + atlasul), deci
## 4-7 desene de umbra pe model si felie; pasa de umbra nu are nevoie de
## materiale, deci un singur desen ajunge. Umbra iese identica. Kyoto, nov
## 2026: in curba de dupa start (frac 0,10) telefonul ramanea la 27 fps cu
## 706 + 396 desene, iar casele dadeau 218 din cele 318 desene de umbra ale
## sondei (profilul de telefon: o cascada, 55 m).
@export var shadow_proxy: bool = true
@export var seed_value: int = 20260929
## Zone fara case (centru XZ in coordonate de lume + raza), pe langa
## golurile `TerrainHollow` (fantana) care se exclud singure.
@export var exclude_xz: PackedVector3Array = PackedVector3Array()
## ZONA PROPRIE (opt-in; gol = interiorul buclei, comportamentul dinainte):
## poligon XZ in coordonate de lume care INLOCUIESTE bucla ca zona de umplut.
## Kyoto (Track18, POI A): orasul vechi e doar o parte din interior (iazul F,
## dealul gradinii si padurile raman libere), iar cartierul din jurul pagodei
## Yasaka e in AFARA buclei, la nord de B. Restul regulilor (distanta de banda,
## goluri, treapta de teren) raman aceleasi.
@export var region_xz: PackedVector2Array = PackedVector2Array()

## SIRURI LIPITE (opt-in; false = grila de case izolate, comportamentul de
## dinainte, Jodhpur neschimbat). Kyoto, POI A r3: grila de 10 m cu case
## izolate citea „cartier de blocuri". Machiya reale sunt LIPITE in siruri de-a
## lungul ulitelor inguste, doua siruri spate in spate intre doua ulite, cu fata
## spre ulita. Regiunea se imparte in CARTIERE patrate de `row_district_m`;
## fiecare cartier are directia lui de ulite (din `row_angles_deg`, plus
## +-6 grade), iar intre cartiere ramane o ulita de margine (`row_district_gap_m`).
## Fata casei e -Z local (front_yaw_deg se ignora in modul asta).
@export var row_mode: bool = false
## Pasul in lungul sirului = latimea casei (fara gol lateral).
@export var row_house_w: float = 6.3
## Distanta intre axele celor doua siruri spate in spate (streasinile din
## spate se ating la 2 x 3,5 m pe machiya).
@export var row_back_to_back_m: float = 7.0
## Distanta intre axa casei si fata ei (peretele de lemn).
@export var row_front_m: float = 2.66
## Latimea ulitei dintre doua blocuri (perete la perete).
@export var row_alley_m: float = 7.0
@export var row_district_m: float = 90.0
@export var row_district_gap_m: float = 7.0
@export var row_angles_deg: PackedFloat32Array = PackedFloat32Array([0.0, 14.0, -18.0, 32.0, -35.0])
@export var row_yaw_jitter_deg: float = 4.0
@export var row_scale_min: float = 0.92
@export var row_scale_max: float = 1.08
## Ulita transversala: din `row_break_min`..`row_break_max` case, un loc de
## casa ramane gol (sirurile reale se rup la 30-50 m). 0 = siruri continue.
@export var row_break_min: int = 5
@export var row_break_max: int = 8

## CASE SUB DRUM (opt-in; 0 = oprit, comportamentul dinainte): o casa poate sta
## mai aproape de `min_road_m` — dar nu sub `below_road_m` — de orice punct de
## banda fata de care terenul ei e cu cel putin `below_drop_m` mai JOS. Regula
## de 40 m exista fiindca umplutura n-are coliziune; o casa cu 20 m sub buza
## unui bastion nu e ceva in care intra o masina, e ce vede soferul cand se
## uita in jos (Jodhpur, POI F: piciorul abruptului e la 36-40 m de drum).
@export var below_road_m: float = 0.0
@export var below_drop_m: float = 15.0

## CASELE CU FATA SPRE UN PUNCT (x, z, raza; raza 0 = oprit, comportamentul
## dinainte). Casele din raza se rotesc — tot in pasi de 90°, ca grila de ulite
## sa ramana dreapta, cu acelasi jitter de ±6° — pe pasul cel mai apropiat de
## directia spre punct. Jodhpur: punctul e varful bastionului (POI F), ca de
## pe bastion orasul de la piciorul stancii sa arate fatade, nu spate.
## Pozitiile nu se schimba (rotirea e dupa alegerea modelului, pe acelasi rng).
@export var face_xz: Vector3 = Vector3.ZERO
## Unde e FATA fiecarui model (aceeasi ordine ca `models`), ca unghi Y in grade
## fata de −Z: 0 = fata pe −Z, −90 = fata pe +X. Gol = toate pe −Z.
@export var front_yaw_deg: PackedFloat32Array = PackedFloat32Array()

## INSTANTE EXPLICITE (opt-in; gol = generarea de mai sus, comportamentul
## dinainte, Jodhpur neschimbat). Kyoto, POI B r2: randurile de case FARA corp
## din spatele primului rand (A si B) erau noduri DecorManual, ~4 desene pe
## casa (+854 desene pe pista). Generatorul POI-ului isi calculeaza el
## transformarile — orientarea de strada ramane exact cea aleasa acolo — si le
## da aici; nodul doar le deseneaza ca MultiMesh feliat, cu aceleasi sabloane
## de material. Pas de 13 numere pe instanta: indicele modelului in `models`,
## coloanele bazei (x, y, z: 9 numere) si originea (3). Cu lista nevida,
## regiunea, min_road_m, exclude_xz si row_mode se ignora.
@export var explicit_xforms: PackedFloat32Array = PackedFloat32Array()

## N TENTE DE PERETE (opt-in; gol = cele doua tente de dinainte, deschis / indigo dupa
## `indigo_ratio`, Jodhpur si Kyoto neschimbate). San Francisco, pasul 8b: cele cinci pasteluri ale
## casei de rand, aceeasi idee ca `WorldProp.WALL_CLASS_META` — numele claselor de perete, PRIMA fiind
## clasa pe care modelul o poarta din `CLASSES_BY_MODEL` (baza, `sf_clapboard`). Fiecare casa ia o
## singura clasa: din `explicit_wall` (randurile date de generator) sau trasa dupa `wall_weights`,
## mereu alta decat a casei de dinainte (vecinul din sir).
@export var wall_classes: PackedStringArray = PackedStringArray()
@export var wall_weights: PackedFloat32Array = PackedFloat32Array()
## PASTELUL PE INSTANTA (doar cu `wall_classes`): cand clasele difera DOAR prin tenta (aceeasi dala,
## aceeasi scara triplanara — cazul `sf_clapboard*`), peretele fiecarui model e UN singur buffer pe
## materialul bazei, iar pastelul vine din culoarea instantei (materialul are
## `vertex_color_use_as_albedo`, deci culoarea instantei inmulteste albedo-ul): culoarea =
## tenta clasei / tenta bazei, in spatiul liniar, adica exact albedo-ul clasei. Zero materiale noi si
## de N ori mai putine buffere de perete. Daca vreo clasa difera si prin altceva decat tenta, se cade
## singur pe un sablon per clasa (un buffer de perete pe model, clasa si celula).
@export var wall_tint_per_instance: bool = true
## KITUL OGLINDIT (opt-in; gol = comportamentul dinainte): pentru fiecare model din `models`, fisierul
## lui oglindit DE-ADEVARATELEA (`_m`, aceeasi ordine; null = fara pereche). O instanta ceruta cu
## determinant NEGATIV (scale.x = -1: „garajul pe cealalta mana") s-ar desena pe dos intr-un
## MultiMesh (memoria `multimesh-oglindire-culling`); aici se deseneaza cu mesh-ul `_m` si cu
## transformarea refacuta POZITIVA (axa X intoarsa inapoi), deci imaginea e aceeasi.
@export var mirror_models: Array[PackedScene] = []
## Clasa de perete a fiecarei instante explicite (indice in `wall_classes`, aceeasi ordine ca
## `explicit_xforms`); gol = trasa dupa `wall_weights`.
@export var explicit_wall: PackedInt32Array = PackedInt32Array()
## Umbra aruncata a fiecarei instante explicite (1 = arunca prin `shadow_proxy`, 0 = nu); gol = toate
## arunca. Randurile din spate departe de drum nu intra niciodata in cascada de umbra a camerei, dar
## un buffer de umbra se deseneaza intreg daca ii atinge AABB-ul: scoase din el, nu costa nimic.
@export var explicit_shadow: PackedInt32Array = PackedInt32Array()
## Feliaza si instantele explicite pe `cell_m` (opt-in; false = o singura felie, ca pana acum):
## pentru umpluturi explicite intinse pe tot orasul, nu pe o fasie.
@export var explicit_cells: bool = false

var stats := {}


var _cell_forced: bool = false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--indigo="):
			indigo_ratio = clampf(float(a.trim_prefix("--indigo=")), 0.0, 1.0)
		elif a.begins_with("--cell="):
			# A/B de feliere in sonde (ProbePerf): si randurile explicite se
			# felieaza atunci, ca sa se vada ce taie frustumul.
			cell_m = maxf(10.0, float(a.trim_prefix("--cell=")))
			_cell_forced = true
		elif a == "--no-shadow-proxy":
			shadow_proxy = false
	if Engine.is_editor_hint() or models.is_empty():
		return
	# Comutatorul de test „Test: build houses" (GameState.dbg_build_houses).
	# Prin cale, nu prin numele autoload-ului: scriptul se incarca si fara el.
	var gs := get_node_or_null(^"/root/GameState")
	if gs != null:
		match int(gs.get("dbg_build_houses")):
			1:
				shadow_proxy = false
			2:
				_trace("CityFill %s: SKIP (test)" % name)
				return
	_build.call_deferred()


## Pas in urma incarcarii (GameState.load_trace): unde moare telefonul.
func _trace(msg: String) -> void:
	var gs := get_node_or_null(^"/root/GameState")
	if gs != null and gs.has_method(&"load_trace"):
		gs.call(&"load_trace", msg)


func _build() -> void:
	var track := _find_track()
	if track == null:
		# Instantele explicite nu cer pista (doar generarea pe teren); sonda de tenta
		# (tools/ProbeSfTenta.tscn) deseneaza umplutura pe o scena goala.
		if explicit_xforms.is_empty():
			push_warning("CityFill %s: nu gasesc pista" % name)
			return
	# Terenul trebuie sa fie in spatiul fizic inainte de raycast-uri.
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var t0 := Time.get_ticks_msec()
	_trace("CityFill %s: start (shadow_proxy %s)" % [name, shadow_proxy])
	var places: Array
	if not explicit_xforms.is_empty():
		places = _explicit()
	else:
		places = _generate_rows(track, space) if row_mode else _generate(track, space)
	_trace("CityFill %s: %d places, templates..." % [name, places.size()])
	# Lista de modele: `models`, apoi perechile oglindite (indicele `models.size() + i` = oglinda
	# lui `models[i]`). Fara `mirror_models` lista e exact `models`.
	var all_models: Array[PackedScene] = models.duplicate()
	for i in models.size():
		all_models.append(mirror_models[i] if i < mirror_models.size() else null)
	# Modul de tenta: 0 = cele doua tente de dinainte; 1 = un sablon per clasa din `wall_classes`;
	# 2 = pastelul pe instanta (un sablon, culoarea instantei pe perete).
	var mode := 0
	if not wall_classes.is_empty():
		mode = 2 if wall_tint_per_instance and _tint_compatible() else 1
	var wall_rgb: Array[Color] = []
	var parts: Array
	if mode == 0:
		parts = await _templates([{}, {WorldProp.LIME_INDIGO_META: true}], models)
	else:
		# Doar modelele folosite (perechile `_m` nefolosite nu se instantiaza).
		var used := {}
		for p: Dictionary in places:
			var m0: int = int(p["mi"]) if p.has("mi") else -1
			if m0 >= 0:
				used[m0] = true
				if (p["xf"] as Transform3D).basis.determinant() < 0.0 and all_models[models.size() + m0] != null:
					used[models.size() + m0] = true
		if used.is_empty() or places.any(func(p: Dictionary) -> bool: return not p.has("mi")):
			for i in all_models.size():
				if all_models[i] != null:
					used[i] = true
		var variants: Array = [{}]
		if mode == 1:
			variants = []
			for c in wall_classes:
				variants.append({WorldProp.WALL_CLASS_META: c})
		var list: Array[PackedScene] = []
		for i in all_models.size():
			list.append(all_models[i] if used.has(i) else null)
		parts = await _templates(variants, list, mode == 2)
		if mode == 2:
			var base := Palette.triplanar_class_material(wall_classes[0]).albedo_color.srgb_to_linear()
			for c in wall_classes:
				var t := Palette.triplanar_class_material(c).albedo_color.srgb_to_linear()
				wall_rgb.append(Color(t.r / maxf(base.r, 1e-4), t.g / maxf(base.g, 1e-4),
					t.b / maxf(base.b, 1e-4), 1.0))
	_trace("CityFill %s: templates done, batching" % name)
	var groups := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	var wrng := RandomNumberGenerator.new()
	wrng.seed = seed_value + 11
	var counts := PackedInt32Array()
	counts.resize(models.size() if mirror_models.is_empty() else all_models.size())
	var indigo_n := 0
	var per_wall := PackedInt32Array()
	per_wall.resize(wall_classes.size())
	var prev_wall := -1
	var swapped := 0
	var inside_out := 0
	var casters := 0
	for p: Dictionary in places:
		var mi: int = int(p["mi"]) if p.has("mi") else _pick(rng)
		var variant := 0
		var wi := 0
		if mode == 0:
			var ind := rng.randf() < indigo_ratio
			if ind:
				indigo_n += 1
			variant = int(ind)
		else:
			wi = int(p["wall"]) if p.has("wall") else _pick_wall(wrng, prev_wall)
			wi = clampi(wi, 0, wall_classes.size() - 1)
			prev_wall = wi
			per_wall[wi] += 1
			variant = wi if mode == 1 else 0
		var casts: bool = bool(p.get("shadow", true))
		var xf: Transform3D = p["xf"]
		if face_xz.z > 0.0:
			xf = _faced(xf, mi)
		if xf.basis.determinant() < 0.0:
			# Mana cealalta: mesh-ul `_m` cu transformarea refacuta pozitiva.
			if models.size() + mi < all_models.size() and all_models[models.size() + mi] != null:
				mi += models.size()
				xf.basis.x = -xf.basis.x
				swapped += 1
			else:
				inside_out += 1
		counts[mi] += 1
		if casts:
			casters += 1
		var cell := Vector2i(floori(xf.origin.x / cell_m), floori(xf.origin.z / cell_m))
		if not explicit_xforms.is_empty() and not _cell_forced 				and visibility_end_m <= 0.0 and not explicit_cells:
			# Randurile explicite sunt o fasie de cateva sute de metri langa
			# drum: o singura felie (altfel axele x = 0 / z = 0 le taie in
			# patru si dubleaza desenele fara castig de culling). Cu taiere pe
			# distanta se felieaza: altfel fasia ar fi taiata toata odata.
			cell = Vector2i.ZERO
		for part: Dictionary in parts[mi]:
			if part["variant"] != -1 and int(part["variant"]) != variant:
				continue
			if part.get("shadow", false) and not casts:
				continue
			var key := "%d|%d|%d|%d" % [mi, part["id"], cell.x, cell.y]
			if not groups.has(key):
				groups[key] = {"part": part, "xfs": [], "cell": cell, "model": mi, "cols": []}
			(groups[key]["xfs"] as Array).append(xf * (part["local"] as Transform3D))
			if part.get("tint", false):
				(groups[key]["cols"] as Array).append(wall_rgb[wi])
	var batches := 0
	var tris := 0
	for key: String in groups:
		var g: Dictionary = groups[key]
		var part: Dictionary = g["part"]
		var xfs: Array = g["xfs"]
		var cols: Array = g["cols"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		# Culorile se cer INAINTE de numarul de instante (MultiMesh refuza altfel).
		mm.use_colors = not cols.is_empty()
		mm.mesh = part["mesh"]
		mm.instance_count = xfs.size()
		for i in cols.size():
			mm.set_instance_color(i, cols[i])
		# Nodul sta in centrul caselor lui, ca distanta de taiere sa se masoare
		# de acolo si nu de la originea pistei.
		var center := Vector3.ZERO
		for xf_i: Transform3D in xfs:
			center += xf_i.origin
		center /= float(xfs.size())
		for i in xfs.size():
			var xf_i: Transform3D = xfs[i]
			mm.set_instance_transform(i, Transform3D(xf_i.basis, xf_i.origin - center))
		var mmi := MultiMeshInstance3D.new()
		mmi.position = center
		mmi.visibility_range_end = visibility_end_m
		if shadow_proxy:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
				if part.get("shadow", false) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.name = "CityFill_%s__p%d_%d_%d" % [
			all_models[int(g["model"])].resource_path.get_file().get_basename(),
			int(part["id"]), (g["cell"] as Vector2i).x, (g["cell"] as Vector2i).y]
		mmi.multimesh = mm
		mmi.material_override = part["material"]
		add_child(mmi)
		batches += 1
		if not part.get("shadow", false):
			tris += int(part["tris"]) * xfs.size()
	var cen := Vector3.ZERO
	for p: Dictionary in places:
		cen += (p["xf"] as Transform3D).origin
	cen /= maxf(float(places.size()), 1.0)
	var rej: Dictionary = stats.get("rejected", {})
	stats = {"below_road": stats.get("below_road", 0), "houses": places.size(), "indigo": indigo_n, "batches": batches, "centroid": cen, "rejected": rej,
		"tris": tris, "ms": Time.get_ticks_msec() - t0, "per_model": counts}
	if mode == 0:
		print("CityFill %s: %d case (%d indigo, raport %.2f), %d buffere, %d tri, %d ms, centroid (%.0f, %.1f, %.0f), respinse %s" % [
			name, places.size(), indigo_n, indigo_ratio, batches, tris, stats["ms"],
			cen.x, cen.y, cen.z, str(stats.get("rejected", {}))])
	else:
		stats["per_wall"] = per_wall
		stats["wall_mode"] = "instanta" if mode == 2 else "clasa"
		stats["mirrored"] = swapped
		stats["inside_out"] = inside_out
		stats["casters"] = casters
		print("CityFill %s: %d case, tente %s pe %s %s, %d oglindite pe `_m`, %d pe dos, %d arunca umbra, %d buffere, %d tri, %d ms" % [
			name, places.size(), str(Array(wall_classes)), stats["wall_mode"], str(Array(per_wall)),
			swapped, inside_out, casters, batches, tris, stats["ms"]])
	_trace("CityFill %s: done, %d buffers, %d ms" % [name, batches, int(stats["ms"])])


## Instantele date de generator (vezi `explicit_xforms`).
func _explicit() -> Array:
	var out: Array = []
	var f := explicit_xforms
	var i := 0
	while i + 13 <= f.size():
		var b := Basis(Vector3(f[i + 1], f[i + 2], f[i + 3]),
			Vector3(f[i + 4], f[i + 5], f[i + 6]), Vector3(f[i + 7], f[i + 8], f[i + 9]))
		var mi := clampi(int(f[i]), 0, models.size() - 1)
		var d := {"mi": mi, "xf": Transform3D(b, Vector3(f[i + 10], f[i + 11], f[i + 12]))}
		var k := out.size()
		if k < explicit_wall.size():
			d["wall"] = explicit_wall[k]
		if k < explicit_shadow.size():
			d["shadow"] = explicit_shadow[k] != 0
		out.append(d)
		i += 13
	stats["rejected"] = {}
	stats["below_road"] = 0
	return out


## Rotirea spre `face_xz` (vezi exportul): pasul de 90° cel mai apropiat de
## directia spre punct, pastrand jitterul original al casei.
func _faced(xf: Transform3D, mi: int) -> Transform3D:
	var o := xf.origin
	var to := Vector2(face_xz.x - o.x, face_xz.y - o.z)
	if to.length() > face_xz.z or to.length() < 1.0:
		return xf
	var q := PI * 0.5
	# yaw-ul curent, din baza (Basis(UP, yaw) duce -Z in (-sin, 0, -cos)).
	var f := xf.basis * Vector3(0, 0, -1)
	var yaw := atan2(-f.x, -f.z)
	var jitter := yaw - roundf(yaw / q) * q
	var front := deg_to_rad(front_yaw_deg[mi]) if mi < front_yaw_deg.size() else 0.0
	# fata in lume = Basis(UP, yaw + front) * (0, 0, -1); vrem sa fie `to`.
	var want := atan2(-to.x, -to.y) - front
	return Transform3D(Basis(Vector3.UP, roundf(want / q) * q + jitter), o)


func _pick(rng: RandomNumberGenerator) -> int:
	if weights.size() != models.size():
		return rng.randi_range(0, models.size() - 1)
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return models.size() - 1


## Pozitiile: grila cu jitter pe AABB-ul buclei, pastrand doar punctele din
## INTERIORUL buclei principale, la `min_road_m` de orice banda, in afara
## golurilor de teren si a zonelor excluse, pe teren fara treapta.
func _generate(track: Track, space: PhysicsDirectSpaceState3D) -> Array:
	var loop := PackedVector2Array()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in track.baked:
		var q := Vector2(p.x, p.z)
		loop.append(q)
		lo = lo.min(q)
		hi = hi.max(q)
	if not region_xz.is_empty():
		loop = region_xz
		lo = Vector2(INF, INF)
		hi = Vector2(-INF, -INF)
		for q in region_xz:
			lo = lo.min(q)
			hi = hi.max(q)
	var roads := PackedVector2Array()
	var road_y := PackedFloat32Array()
	for r: TrackRoute in track.routes:
		var b: PackedVector3Array = r.baked
		for i in range(0, b.size(), 2):
			roads.append(Vector2(b[i].x, b[i].z))
			road_y.append(b[i].y)
	var holes: Array[Vector3] = []
	for n in _all(track):
		if n is TerrainHollow:
			var h := n as TerrainHollow
			holes.append(Vector3(h.global_position.x, h.global_position.z,
				h.radius_m + h.wall_m + 6.0))
	for e in exclude_xz:
		holes.append(e)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	var rejected := {"road": 0, "hole": 0, "step": 0, "nohit": 0}
	var min2 := min_road_m * min_road_m
	var below2 := below_road_m * below_road_m
	var below_n := 0
	var y := lo.y
	while y <= hi.y:
		var x := lo.x
		while x <= hi.x:
			var c := Vector2(x + rng.randf_range(-jitter_m, jitter_m),
				y + rng.randf_range(-jitter_m, jitter_m))
			var yaw := float(rng.randi_range(0, 3)) * PI * 0.5 \
				+ deg_to_rad(rng.randf_range(-6.0, 6.0))
			x += spacing_m
			if not Geometry2D.is_point_in_polygon(c, loop):
				continue
			var near := false
			var below := false
			var g0 := NAN
			for qi in roads.size():
				var d2 := c.distance_squared_to(roads[qi])
				if d2 >= min2:
					continue
				if below_road_m > 0.0 and d2 >= below2:
					if is_nan(g0):
						g0 = _ground(space, track, c)
					if not is_nan(g0) and road_y[qi] - g0 >= below_drop_m:
						below = true
						continue
				near = true
				break
			if near:
				rejected["road"] += 1
				continue
			if below:
				below_n += 1
			var in_hole := false
			for h in holes:
				if c.distance_to(Vector2(h.x, h.y)) < h.z:
					in_hole = true
					break
			if in_hole:
				rejected["hole"] += 1
				continue
			var hmin := INF
			var hmax := -INF
			var ok := true
			for off: Vector2 in [Vector2.ZERO, Vector2(3.8, 3.8), Vector2(-3.8, 3.8),
					Vector2(3.8, -3.8), Vector2(-3.8, -3.8)]:
				var g := _ground(space, track, c + off)
				if is_nan(g):
					ok = false
					break
				hmin = minf(hmin, g)
				hmax = maxf(hmax, g)
			if not ok:
				rejected["nohit"] += 1
				continue
			if hmax - hmin > max_step_m:
				rejected["step"] += 1
				continue
			out.append({"xf": Transform3D(Basis(Vector3.UP, yaw),
				Vector3(c.x, hmin - sink_m, c.y))})
		y += spacing_m
	stats["rejected"] = rejected
	stats["below_road"] = below_n
	return out


## Modul SIRURI (vezi `row_mode`): cartiere rotite, blocuri de doua siruri
## spate in spate, case lipite cu fata spre ulita. Aceleasi filtre ca grila:
## zona, distanta de banda, goluri/excluderi, treapta de teren.
func _generate_rows(track: Track, space: PhysicsDirectSpaceState3D) -> Array:
	var loop := PackedVector2Array()
	if not region_xz.is_empty():
		loop = region_xz
	else:
		for p in track.baked:
			loop.append(Vector2(p.x, p.z))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in loop:
		lo = lo.min(q)
		hi = hi.max(q)
	var roads := PackedVector2Array()
	for r: TrackRoute in track.routes:
		var b: PackedVector3Array = r.baked
		for i in range(0, b.size(), 2):
			roads.append(Vector2(b[i].x, b[i].z))
	var holes: Array[Vector3] = []
	for n in _all(track):
		if n is TerrainHollow:
			var h := n as TerrainHollow
			holes.append(Vector3(h.global_position.x, h.global_position.z,
				h.radius_m + h.wall_m + 6.0))
	for e in exclude_xz:
		holes.append(e)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	var rejected := {"road": 0, "hole": 0, "step": 0, "nohit": 0}
	var min2 := min_road_m * min_road_m
	var pitch := 2.0 * row_front_m + row_back_to_back_m + row_alley_m
	var half_d := row_district_m * 0.5 - row_district_gap_m * 0.5
	var dz := lo.y
	while dz < hi.y:
		var dx := lo.x
		while dx < hi.x:
			var cen := Vector2(dx + row_district_m * 0.5, dz + row_district_m * 0.5)
			dx += row_district_m
			var ang := deg_to_rad(row_angles_deg[rng.randi_range(0, row_angles_deg.size() - 1)]
				+ rng.randf_range(-6.0, 6.0))
			var ax := Vector2(cos(ang), -sin(ang))   # in lungul sirului (X local)
			var az := Vector2(sin(ang), cos(ang))    # peste siruri (Z local)
			var off := rng.randf_range(0.0, pitch)
			var v := -half_d * 1.42 + off
			while v < half_d * 1.42:
				# doua siruri: fata spre -Z (ulita din „spate" a lui v) si spre +Z
				for k in 2:
					var row_v := v + (row_front_m if k == 0 else row_front_m + row_back_to_back_m)
					var row_yaw := ang + (0.0 if k == 0 else PI)
					var u := -half_d * 1.42 + rng.randf_range(0.0, row_house_w)
					var run := 0
					var brk := rng.randi_range(row_break_min, row_break_max) if row_break_max > 0 else 1 << 30
					while u < half_d * 1.42:
						var c := cen + ax * u + az * row_v
						u += row_house_w
						run += 1
						if run > brk:
							run = 0
							brk = rng.randi_range(row_break_min, row_break_max)
							continue
						var lc := c - cen
						if absf(lc.x) > half_d or absf(lc.y) > half_d:
							continue
						if not Geometry2D.is_point_in_polygon(c, loop):
							continue
						var near := false
						for q in roads:
							if c.distance_squared_to(q) < min2:
								near = true
								break
						if near:
							rejected["road"] += 1
							continue
						var in_hole := false
						for h in holes:
							if c.distance_to(Vector2(h.x, h.y)) < h.z:
								in_hole = true
								break
						if in_hole:
							rejected["hole"] += 1
							continue
						var hmin := INF
						var hmax := -INF
						var ok := true
						for o: Vector2 in [Vector2.ZERO, Vector2(3.2, 3.2), Vector2(-3.2, 3.2),
								Vector2(3.2, -3.2), Vector2(-3.2, -3.2)]:
							var g := _ground(space, track, c + o)
							if is_nan(g):
								ok = false
								break
							hmin = minf(hmin, g)
							hmax = maxf(hmax, g)
						if not ok:
							rejected["nohit"] += 1
							continue
						if hmax - hmin > max_step_m:
							rejected["step"] += 1
							continue
						var yaw := row_yaw + deg_to_rad(rng.randf_range(-row_yaw_jitter_deg, row_yaw_jitter_deg))
						var sc := rng.randf_range(row_scale_min, row_scale_max)
						out.append({"xf": Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc)),
							Vector3(c.x, hmin - sink_m, c.y))})
				v += pitch
		dz += row_district_m
	stats["rejected"] = rejected
	stats["below_road"] = 0
	return out


## Cota terenului REAL (TerrainBody) sub (x, z); NAN daca raza nu-l gaseste.
func _ground(space: PhysicsDirectSpaceState3D, track: Track, c: Vector2) -> float:
	var from := Vector3(c.x, 400.0, c.y)
	var to := Vector3(c.x, -200.0, c.y)
	var exclude: Array[RID] = []
	for i in 6:
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name).begins_with("TerrainBody"):
			return (hit["position"] as Vector3).y
		exclude.append(hit["rid"])
	return NAN


## Sabloanele: fiecare model o data pe VARIANTA (o varianta = metadatele puse pe instanta: azi
## {} deschis si {indigo} pe Jodhpur, sau {wall_class} pe clasa) sub un WorldProp temporar copil
## al acestui nod — deci sub pista, cu tema reala (memoria `decor-ready-inaintea-temei`) — si
## citite DUPA apelurile amanate. Un model null in `list` nu se instantiaza (lista lui de parti e
## goala). Intoarce, per model, lista de parti {id, mesh, material, local, variant, tris};
## `variant` = -1 (comuna) sau indicele variantei. Cu `tint`, partile pe materialul clasei de baza
## (`wall_classes[0]`) primesc `tint` (culoarea instantei).
func _templates(variants: Array, list: Array[PackedScene], tint: bool = false) -> Array:
	var holder := Node3D.new()
	holder.name = "CityFillTemplates"
	holder.set_script(load("res://scenes/props/world_prop.gd"))
	holder.set("auto_collision", false)
	var roots: Array = []
	for m in list:
		if m == null:
			roots.append(null)
			continue
		var pair: Array = []
		for v in variants.size():
			var inst := m.instantiate() as Node3D
			var metas: Dictionary = variants[v]
			for key: String in metas:
				inst.set_meta(key, metas[key])
			holder.add_child(inst)
			pair.append(inst)
		roots.append(pair)
	add_child(holder)
	await get_tree().process_frame
	await get_tree().process_frame
	var world := Palette.world_material()
	var base_wall: Material = Palette.triplanar_class_material(wall_classes[0]) if tint else null
	# Modul vechi (fara `wall_classes`) ramane octet cu octet: LOD-uri generate pe toate partile,
	# atlasul unit mereu. Modul nou pastreaza LOD-urile importului unde mesh-ul e cel importat.
	var keep_import := not wall_classes.is_empty()
	var out: Array = []
	for mi_idx in roots.size():
		var parts: Array = []
		if roots[mi_idx] == null:
			out.append(parts)
			continue
		var atlas_st: ArrayMesh = null
		var atlas_tris := 0
		var atlas_src: Array = []      # [mesh, local] ale nodurilor de atlas (varianta 0)
		var shadow_st: ArrayMesh = null
		for v in variants.size():
			var root: Node3D = roots[mi_idx][v]
			for mi in _meshes(root):
				var local := _xf_to(mi, root)
				var mat := mi.material_override
				# Forma e aceeasi in toate variantele (difera doar materialul).
				if shadow_proxy and v == 0 						and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					for s in mi.mesh.get_surface_count():
						var sh := SurfaceTool.new()
						sh.append_from(mi.mesh, s, local)
						shadow_st = sh.commit(shadow_st)
				if mat == world or mat == null:
					if v != 0:
						continue # atlasul e comun tuturor variantelor
					atlas_src.append([mi.mesh, local])
					for s in mi.mesh.get_surface_count():
						var st := SurfaceTool.new()
						st.append_from(mi.mesh, s, local)
						atlas_st = st.commit(atlas_st)
						atlas_tris += _tris(mi.mesh, s)
				else:
					var tr := 0
					for s in mi.mesh.get_surface_count():
						tr += _tris(mi.mesh, s)
					var part := {"id": parts.size() + 1, "mesh": mi.mesh,
						"material": mat, "local": local, "variant": v, "tris": tr}
					if tint and mat == base_wall:
						part["tint"] = true
					parts.append(part)
		if generate_lods:
			for part: Dictionary in parts:
				if keep_import and _has_lods(part["mesh"]):
					continue
				part["mesh"] = _with_lods(part["mesh"])
		if keep_import and atlas_src.size() == 1 and (atlas_src[0][0] as Mesh).get_surface_count() == 1:
			# Un singur nod de atlas cu o singura suprafata: mesh-ul importului, cu LOD-urile lui,
			# nu o copie unita (care le-ar pierde si ar trebui sa le genereze din nou).
			var am: Mesh = atlas_src[0][0]
			if generate_lods and not _has_lods(am):
				am = _with_lods(am)
			parts.append({"id": 0, "mesh": am, "material": world,
				"local": atlas_src[0][1], "variant": -1, "tris": atlas_tris})
		elif atlas_st != null:
			# Atlasul vine din mai multe noduri (2 suprafete pe machiya a/b/d):
			# unite, sunt un desen in loc de doua. Acelasi format, deci nimic nu
			# se pierde la lipire.
			parts.append({"id": 0, "mesh": _one_surface(atlas_st), "material": world,
				"local": Transform3D.IDENTITY, "variant": -1, "tris": atlas_tris})
		if shadow_st != null:
			parts.append({"id": parts.size() + 1, "shadow": true, "variant": -1,
				"mesh": _one_surface(shadow_st), "material": world,
				"local": Transform3D.IDENTITY, "tris": 0})
		out.append(parts)
	holder.queue_free()
	return out


## Are mesh-ul LOD-uri (ale importului sau generate)? Citirea trece prin registrul `MeshCpu`.
func _has_lods(mesh: Mesh) -> bool:
	for s in mesh.get_surface_count():
		if MeshCpu.surface_lods(mesh, s).is_empty():
			return false
	return mesh.get_surface_count() > 0


## Clasele din `wall_classes` difera DOAR prin tenta fata de prima (aceeasi dala, aceeasi proiectie)?
## Atunci pastelul poate sta in culoarea instantei (vezi `wall_tint_per_instance`).
func _tint_compatible() -> bool:
	var base := Palette.triplanar_class_material(wall_classes[0])
	for c in wall_classes:
		var m := Palette.triplanar_class_material(c)
		if m.albedo_texture != base.albedo_texture or m.uv1_scale != base.uv1_scale 				or m.uv1_triplanar != base.uv1_triplanar 				or m.uv1_world_triplanar != base.uv1_world_triplanar 				or m.uv1_triplanar_sharpness != base.uv1_triplanar_sharpness 				or m.roughness != base.roughness or m.metallic_specular != base.metallic_specular 				or m.texture_filter != base.texture_filter or not m.vertex_color_use_as_albedo 				or m.albedo_color.a != base.albedo_color.a:
			return false
	return true


## Clasa de perete a casei urmatoare dupa `wall_weights` (egale daca lipsesc), alta decat `prev`.
func _pick_wall(rng: RandomNumberGenerator, prev: int) -> int:
	var n := wall_classes.size()
	var total := 0.0
	for i in n:
		if i != prev:
			total += wall_weights[i] if wall_weights.size() == n else 1.0
	var r := rng.randf() * total
	for i in n:
		if i == prev:
			continue
		r -= wall_weights[i] if wall_weights.size() == n else 1.0
		if r <= 0.0:
			return i
	return (prev + 1) % n


## Toate suprafetele intr-una singura (= un desen). `commit` pe acelasi
## ArrayMesh adauga o suprafata noua la fiecare apel, deci le lipim aici.
func _one_surface(src: ArrayMesh) -> Mesh:
	var st := SurfaceTool.new()
	for s in src.get_surface_count():
		st.append_from(src, s, Transform3D.IDENTITY)
	var one := st.commit()
	return _with_lods(one) if generate_lods else one


## Acelasi mesh, cu LOD-uri generate (ImporterMesh, ca la importul GLB).
func _with_lods(src: Mesh) -> Mesh:
	# Unghiurile importerului (60, 25), nu inversate: cu (25, 60) casa albastra
	# `blue_house_a` cobora doar la 261 de triunghiuri, acum la 105 — nivelul
	# grosier e „doar acoperisul si zidurile", exact ce se vede de la 200 m.
	var out := MeshCpu.with_lods(src)
	return out if out.get_surface_count() > 0 else src


func _tris(mesh: Mesh, s: int) -> int:
	var arr: Array = mesh.surface_get_arrays(s)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	return (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		for k in c.get_children():
			st.append(k)
		var mi := c as MeshInstance3D
		if mi != null and mi.mesh != null and mi.visible:
			out.append(mi)
	return out


func _xf_to(n: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		out.append(c)
		for k in c.get_children():
			st.append(k)
	return out


func _find_track() -> Track:
	var cur: Node = get_parent()
	while cur != null:
		if cur is Track:
			return cur as Track
		cur = cur.get_parent()
	return null
