class_name TrackDecor
extends RefCounted
## Decorul din jurul soselei: pietre, cactusi, tufe, mese, copaci.
##
## DOUA STRATEGII, dupa tema:
##
## [b]desert[/b] — BENZI paralele cu drumul, esantionate in arc-length. Fiecare
## banda are propriul offset, pas si continut, iar prop-urile se aseaza in
## grupuri cu goluri intre ele. Asa se obtine senzatia de canion: decorul
## URMEAZA drumul si il strange, in loc sa fie presarat prin peisaj.
##
## [b]forest[/b] — esantionare prin respingere intr-un dreptunghi, codul vechi.
## Padurea nu are nevoie sa stranga drumul, iar schimbarea ar fi rescris doua
## piste care arata bine.
##
## De ce s-a schimbat: metoda veche respingea orice pozitie mai apropiata de 15m
## de axa, deci nu PUTEA produce "lipit de drum" — de asta decorul parea rar desi
## erau 80 de prop-uri.
##
## Materialele NU se creeaza aici: `mat_provider` e cache-ul de culoare din
## [code]track.gd[/code] ([code]_flat_material[/code]). Daca decorul si-ar face
## materiale proprii, garda de draw call-uri din [code]tools/probe_decor.gd[/code]
## ar deveni oarba exact acolo unde conteaza cel mai mult.

## --- Tema forest: esantionare prin respingere (cod vechi) ---
const MAX_PLACED: int = 80
const MAX_ATTEMPTS: int = 400
const NEAR_MARGIN: float = 8.0
const FAR_LIMIT: float = 90.0

## --- Tema desert: benzi paralele cu drumul ---
##
## Tinta e 18-25 prop-uri / 100 m (style_bible §7), adica ~210-290 pe un tur de
## Dunele (1175 m) — fata de 80 cat producea metoda veche pe toata suprafata.
##
## ATENTIE la pas: numarul final NU e lungimea / pas. Fiecare slot se produce pe
## AMBELE laturi, gruparea adauga 2-5 sateliti, iar jitterul longitudinal mai
## strecoara sloturi. Prima incercare (pas 9/7/14) a scos 882 de prop-uri, de
## patru ori peste tinta, si a spart pragul de triunghiuri din garda. Pasii de
## mai jos sunt calibrati pe numaratoarea reala, nu pe calculul naiv.
##
## `off_min`/`off_max` sunt distante fata de MARGINEA asfaltului, nu fata de axa.
## `collide` fals inseamna mesh fara corp fizic: treci prin el.
const BANDS := [
	# Lipita de drum. Da ingustimea canionului, dar NU exista fizic — style_bible
	# §2 cere prop-uri la 2-4m, iar la distanta aia coliziunea ar face cursa
	# nejucabila (is_on_road taie viteza deja de la 7.5m de axa).
	{"name": "hug", "off_min": 1.5, "off_max": 4.0, "spacing": 9.0,
		"collide": false, "cluster": 0.30},
	# Prima banda cu coliziune. La 4m de margine, primul contact posibil e la 11m
	# de axa — adica 3.5m DUPA ce ai incasat deja penalizarea de offroad.
	{"name": "mid", "off_min": 4.0, "off_max": 11.0, "spacing": 25.0,
		"collide": true, "cluster": 0.45},
	# Fundal apropiat: piese mari, rare.
	{"name": "back", "off_min": 11.0, "off_max": 26.0, "spacing": 42.0,
		"collide": true, "cluster": 0.35},
]
## Cati sateliti primeste un prop cand pica zarul de grupare, si in ce raza.
const CLUSTER_MIN: int = 2
const CLUSTER_MAX: int = 5
const CLUSTER_RADIUS: float = 3.5
## In zonele de franare banda lipita se goleste si cea de mijloc se retrage.
const BRAKING_MIN_OFFSET: float = 8.0


## Construieste tot decorul si il intoarce sub un singur nod.
##
## `mode` vine din tema pistei (Track.themes(), cheia "decor"), nu din numele
## temei. Inainte era chiar numele — `if theme == "desert"` — ceea ce lega
## strategia de asezare de o pista anume: o tema noua care voia benzi trebuia
## sa se prefaca ca e desert sau sa adauge inca un `or`.
##   "bands"   — benzi paralele cu drumul, densitatea din style_bible §7
##   "scatter" — esantionare prin respingere in dreptunghi (metoda veche)
##
## `mat_provider` = Callable(Color) -> StandardMaterial3D.
## `props` alege CE se aseaza; `mode` alege UNDE. Sunt doua decizii separate,
## si trebuiau sa fie: insula foloseste aceeasi strategie de benzi ca desertul
## (densitatea din style_bible §7 e cea corecta), dar cu palmieri in loc de
## cactusi. Cat timp ambele veneau din acelasi sir "desert", nu se putea una
## fara cealalta.
static func build(sampler: TrackSideSampler, mode: String, seed_value: int,
		mat_provider: Callable, props: String = "desert") -> Node3D:
	var root := Node3D.new()
	root.name = "Decor"
	# Un singur nod misca toata vegetatia. Se pune primul, ca _add_scatter sa-l
	# gaseasca dupa nume fara sa-l caram prin sase semnaturi de functie.
	var sway := SwayDriver.new()
	sway.name = "Sway"
	root.add_child(sway)
	if sampler.point_count() == 0:
		return root
	if mode == "bands":
		_build_bands(root, sampler, seed_value, mat_provider, props)
	else:
		_build_scattered(root, sampler, seed_value, mat_provider)
	return root


## Benzi paralele cu drumul. Continutul lor vine din `props`, nu de aici.
static func _build_bands(root: Node3D, sampler: TrackSideSampler,
		seed_value: int, mat_provider: Callable, props: String) -> void:
	for band in BANDS:
		# Un rng PER BANDA: asa poti itera pe densitatea benzii de mijloc fara sa
		# se mute si pietricelele de langa drum.
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + hash(band["name"])

		var container := Node3D.new()
		container.name = "Band_%s" % band["name"]
		root.add_child(container)

		var skip := 0
		for spec in sampler.sample_band(band["spacing"], band["off_min"],
				band["off_max"], rng):
			# Golurile sunt la fel de importante ca prop-urile: fara ele iese un
			# covor uniform, nu ritmul "ingramadit / gol" din referinta.
			if skip > 0:
				skip -= 1
				continue
			if not _allowed(spec, band):
				continue
			_place_band_prop(container, spec, band, rng, mat_provider, props)
			if rng.randf() < float(band["cluster"]):
				_place_satellites(container, sampler, spec, band, rng, mat_provider,
					props)
				skip = 2


## Regulile de siguranta, citite din steagurile pe care le-a calculat samplerul.
static func _allowed(spec: TrackDecorSpec, band: Dictionary) -> bool:
	# Rapa declarata: acolo terenul e sapat intentionat, ca sa existe unde sa cazi.
	# Un cactus plutind peste prapastie ar strica exact efectul.
	if spec.is_ravine:
		return false
	if spec.is_braking:
		# 8m liberi in zonele de franare (style_bible §7).
		if band["name"] == "hug":
			return false
		if spec.offset < BRAKING_MIN_OFFSET:
			return false
	# Nimic inalt in apex pe partea interioara: acolo se citeste iesirea din viraj.
	if spec.is_apex and not spec.is_exterior and band["name"] != "hug":
		return false
	return true


static func _place_satellites(parent: Node3D, sampler: TrackSideSampler,
		spec: TrackDecorSpec, band: Dictionary, rng: RandomNumberGenerator,
		mat_provider: Callable, props: String) -> void:
	var count := rng.randi_range(CLUSTER_MIN, CLUSTER_MAX)
	for i in count:
		var sat := TrackDecorSpec.new()
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(1.0, CLUSTER_RADIUS)
		sat.position = spec.position + Vector3(cos(angle), 0.0, sin(angle)) * dist
		# Satelitul s-a imprastiat pana la CLUSTER_RADIUS fata de propul principal,
		# deci cota lui nu mai e cea masurata acolo.
		sat.position.y = sampler.ground_y(sat.position.x, sat.position.z)
		sat.normal_out = spec.normal_out
		sat.along = spec.along
		sat.index = spec.index
		sat.frac = spec.frac
		sat.side_sign = spec.side_sign
		sat.offset = spec.offset + dist * 0.5
		sat.is_exterior = spec.is_exterior
		sat.is_elevated = spec.is_elevated
		sat.is_apex = spec.is_apex
		sat.is_braking = spec.is_braking
		_place_band_prop(parent, sat, band, rng, mat_provider, props, true)


## Ce se aseaza intr-o banda. Sateliti = piese mai mici decat propul principal.
static func _place_band_prop(parent: Node3D, spec: TrackDecorSpec,
		band: Dictionary, rng: RandomNumberGenerator, mat_provider: Callable,
		props: String, satellite: bool = false) -> void:
	if props == "island":
		_place_island_prop(parent, spec.position, band, rng, mat_provider,
			satellite)
		return
	var pos := spec.position
	match band["name"]:
		"hug":
			# Banda lipita de drum avea DOAR scatter — tufe si pietricele de sub
			# 1 m, care la 30 m in fata masinii dispar in nisip. O treime din ea
			# primeste acum stanci mici de canion: singurele obiecte de langa
			# asfalt care au silueta peste linia orizontului si strang cadrul.
			# Fara coliziune, ca toata banda (vezi nota de la BANDS).
			if rng.randf() < 0.34 and _add_canyon_rock(
					parent, pos, rng, CANYON_S, false, 0.75, 1.35):
				return
			_add_scatter(parent, pos, rng, mat_provider)
		"mid":
			var roll := rng.randf()
			if satellite or roll < 0.30:
				if not _add_canyon_rock(parent, pos, rng, CANYON_S, false):
					_add_cluster(parent, pos, rng, ["Cluster_S1", "Cluster_S2"],
						false, mat_provider)
			elif roll < 0.60:
				_add_cactus(parent, pos, rng, mat_provider)
			elif roll < 0.82:
				if not _add_canyon_rock(parent, pos, rng, CANYON_M, true):
					_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
						true, mat_provider)
			else:
				# Bolovanii netezi raman in amestec, in minoritate: doua limbaje
				# de forma pe aceeasi pista citesc ca geologie, unul singur ca
				# tipar.
				_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
					true, mat_provider)
		_:
			var roll2 := rng.randf()
			if satellite or roll2 < 0.30:
				if not _add_canyon_rock(parent, pos, rng, CANYON_M, true):
					_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
						true, mat_provider)
			elif roll2 < 0.72:
				# Aici statea mesa procedurala din cutii. Stancile mari de
				# canion ii iau locul cu aceeasi intentie (silueta dominanta in
				# fundalul apropiat), dar pe textura de roca si cu trepte reale.
				if not _add_canyon_rock(parent, pos, rng, CANYON_L, true,
						0.85, 1.25):
					_add_cluster(parent, pos, rng, ["Cluster_L1"], true,
						mat_provider)
			elif roll2 < 0.86:
				_add_cluster(parent, pos, rng, ["Cluster_L1"], true, mat_provider)
			else:
				_add_cactus(parent, pos, rng, mat_provider)


## --- Set de prop-uri: insula de recif ---------------------------------------
##
## Aceleasi trei benzi, alt continut. Cat timp island_scatter.glb si
## coral_rock.glb nu exista (etapa de assets), fiecare piesa cade pe o primitiva
## colorata din sloturile insulare — NU pe cele de desert. Un cactus pe un recif
## e mai rau decat o tufa provizorie, si ar fi trecut nesanctionat de orice
## sonda: garda numara triunghiuri, nu bunul-simt botanic.
##
## Cand GLB-urile apar, _pick_from_glb le gaseste singur si primitivele dispar.
const ISLAND_SCATTER: String = "res://assets/models/island_scatter.glb"
const ISLAND_ROCKS: String = "res://assets/models/coral_rock.glb"

static func _place_island_prop(parent: Node3D, pos: Vector3, band: Dictionary,
		rng: RandomNumberGenerator, mat: Callable, satellite: bool) -> void:
	match band["name"]:
		"hug":
			# Lipit de drum: iarba de plaja, lemn adus de apa, pietre de corali.
			_add_island_scatter(parent, pos, rng, mat)
		"mid":
			var roll := rng.randf()
			if satellite or roll < 0.34:
				_add_island_scatter(parent, pos, rng, mat)
			elif roll < 0.70:
				_add_palm(parent, pos, rng, mat)
			else:
				_add_coral_rock(parent, pos, rng, mat, true)
		_:
			var roll2 := rng.randf()
			if satellite or roll2 < 0.40:
				_add_coral_rock(parent, pos, rng, mat, true)
			elif roll2 < 0.80:
				_add_palm(parent, pos, rng, mat)
			else:
				_add_coral_rock(parent, pos, rng, mat, true)


## Maruntisuri de plaja, fara coliziune.
static func _add_island_scatter(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	const PICKS := ["Beach_Grass", "Driftwood", "Coral_Pebbles", "Hibiscus"]
	var kept := _pick_from_glb(ISLAND_SCATTER,
		PICKS[rng.randi_range(0, PICKS.size() - 1)])
	if kept == null:
		_add_tropical_bush(parent, pos, rng, mat)
		return
	parent.add_child(kept)
	kept.position = pos + Vector3.UP * -0.15
	kept.rotation.y = rng.randf_range(0.0, TAU)
	kept.scale = Vector3.ONE * rng.randf_range(1.4, 2.1)
	Palette.apply_world_material(kept)


## Tufa subtropicala provizorie: doar vizual, treci prin ea.
## Geamana lui _add_dry_bush, cu slotul de vegetatie tropicala.
static func _add_tropical_bush(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	var bush := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var r := rng.randf_range(0.5, 0.95)
	sphere.radius = r
	sphere.height = r * 1.3 # mai inalta decat lata: tufa de plaja, nu bolovan
	# Rezolutia se seteaza EXPLICIT. Implicit SphereMesh e 64x32 = 4224 de
	# triunghiuri pentru o tufa de 60 cm (CLAUDE.md, constrangeri mobile).
	#
	# 6x2 = ~24 de triunghiuri, nu 8x4 = ~80. Diferenta pare marunta pana o
	# inmultesti cu 461, cati intra pe banda lipita de drum la 1944 m: masurat,
	# 36 880 de triunghiuri, adica 42% din TOATA pista, pentru niste bile care
	# oricum dispar la prima transa de assets. Un placeholder n-are voie sa
	# consume bugetul lucrului pe care il inlocuieste.
	sphere.radial_segments = 6
	sphere.rings = 2
	bush.mesh = sphere
	bush.position = pos + Vector3.UP * (r * 0.35 - 0.3)
	var tint := float(rng.randi_range(0, 2)) / 2.0 * 0.16
	bush.material_override = mat.call(
		Palette.color(Palette.TROPICAL_GREEN).lightened(tint))
	parent.add_child(bush)


## Palmier provizoriu: trunchi inclinat + coroana. Inlocuit de island_scatter.glb.
##
## Inclinarea nu e cosmetica — palmierii de coasta cresc spre lumina, deci un
## pluton de trunchiuri perfect verticale citeste imediat ca geometrie generata.
static func _add_palm(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	var kept := _pick_from_glb(ISLAND_SCATTER,
		"Palm_A" if rng.randf() < 0.6 else "Palm_B")
	if kept != null:
		parent.add_child(kept)
		kept.position = pos
		kept.rotation.y = rng.randf_range(0.0, TAU)
		kept.scale = Vector3.ONE * rng.randf_range(0.9, 1.25)
		Palette.apply_world_material(kept)
		return
	var h := rng.randf_range(4.5, 7.0) # style_bible §2: palmieri 4-7 m
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = pos
	holder.rotation.y = rng.randf_range(0.0, TAU)

	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.28
	cyl.height = h
	cyl.radial_segments = 5
	cyl.rings = 0
	trunk.mesh = cyl
	trunk.position = Vector3(0, h * 0.5, 0)
	trunk.rotation.z = rng.randf_range(-0.22, 0.22)
	trunk.material_override = mat.call(Palette.color(Palette.WOOD_WEATHERED))
	holder.add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = rng.randf_range(1.3, 1.9)
	crown_mesh.height = crown_mesh.radius * 1.1
	crown_mesh.radial_segments = 7
	crown_mesh.rings = 2
	crown.mesh = crown_mesh
	# Urmeaza varful trunchiului inclinat, altfel coroana pluteste langa el.
	crown.position = Vector3(sin(trunk.rotation.z) * -h, h, 0)
	crown.material_override = mat.call(Palette.color(Palette.TROPICAL_GREEN))
	holder.add_child(crown)


## Stanca de corali / bazalt. Placi joase si late, nu bolovani.
static func _add_coral_rock(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable, collide: bool) -> void:
	var kept := _pick_from_glb(ISLAND_ROCKS,
		"Coral_Rock_%02d" % rng.randi_range(1, 8))
	var h := rng.randf_range(0.8, 2.6)
	var node: Node3D
	if kept != null:
		node = kept
		Palette.apply_world_material(kept)
		var mi_glb := _first_mesh(kept)
		if mi_glb != null and mi_glb.mesh != null:
			h = mi_glb.mesh.get_aabb().size.y
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		# Late si turtite: raftul de bazalt sapat de mare, nu o piatra rotunda.
		box.size = Vector3(rng.randf_range(1.8, 4.2), h,
			rng.randf_range(1.6, 3.8))
		mi.mesh = box
		mi.position = Vector3.UP * h * 0.5
		mi.material_override = mat.call(
			Palette.color(Palette.VOLCANIC_BLACK).lightened(
				float(rng.randi_range(0, 2)) / 2.0 * 0.14))
		node = mi
	if not collide:
		parent.add_child(node)
		node.position = pos + Vector3.UP * -0.2
		node.rotation.y = rng.randf_range(0.0, TAU)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.add_child(node)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(h * 0.6, 0.7)
	shape.shape = sphere
	shape.position = Vector3.UP * h * 0.4
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.2


## Tema forest: esantionare prin respingere in dreptunghi (codul dinainte).
static func _build_scattered(root: Node3D, sampler: TrackSideSampler,
		seed_value: int, mat_provider: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var n := sampler.point_count()
	var bounds_min := sampler.baked_point(0)
	var bounds_max := bounds_min
	for i in n:
		var p := sampler.baked_point(i)
		bounds_min = bounds_min.min(p)
		bounds_max = bounds_max.max(p)

	var placed := 0
	var attempts := 0
	while placed < MAX_PLACED and attempts < MAX_ATTEMPTS:
		attempts += 1
		var pos := Vector3(
			rng.randf_range(bounds_min.x - 50.0, bounds_max.x + 50.0),
			0.0,
			rng.randf_range(bounds_min.z - 50.0, bounds_max.z + 50.0))
		# Bug latent, nereclamat: cota era hardcodata 0.0, in timp ce terenul de
		# padure statea la -0.3 plus dune de ±5 m. Copacii de pe Serpentina si
		# Muntele pluteau sau erau ingropati de cand exista pistele alea.
		pos.y = sampler.ground_y(pos.x, pos.z)
		var nearest := sampler.clearance_at(pos)
		if nearest < sampler.half_width() + NEAR_MARGIN or nearest > FAR_LIMIT:
			continue
		placed += 1
		if rng.randf() < 0.7:
			_add_tree(root, pos, rng, mat_provider)
		elif rng.randf() < 0.5:
			_add_glb_rock(root, pos, rng, mat_provider)
		else:
			_add_rock(root, pos, rng, mat_provider)


# ------------------------------------------------------------ prop-uri

## Biblioteca de stanci de canion (canyon_rocks.glb), pe trei clase de marime.
##
## Inlocuieste doua surse care faceau tot desertul sa arate la fel: cei cinci
## elipsoizi netezi din rock_cluster.glb si mesa procedurala de mai jos, care
## era trei cutii suprapuse pe materialul de paleta — fara textura de roca si
## cu muchii perfect drepte. Stancile astea au TREPTE cu buza vizibila si moloz
## la baza; buza e ce se citeste de la 100 m, cand granulatia texturii s-a topit
## in mipmap.
const CANYON_PATH: String = "res://assets/models/canyon_rocks.glb"
const CANYON_S: Array[String] = ["Canyon_S1", "Canyon_S2", "Canyon_S3",
	"Canyon_S4", "Canyon_S5", "Canyon_S6", "Canyon_S7", "Canyon_S8"]
const CANYON_M: Array[String] = ["Canyon_M1", "Canyon_M2", "Canyon_M3",
	"Canyon_M4", "Canyon_M5", "Canyon_M6"]
const CANYON_L: Array[String] = ["Canyon_L1", "Canyon_L2", "Canyon_L3",
	"Canyon_L4"]

## O stanca de canion. Intoarce `false` daca biblioteca lipseste, ca apelantul
## sa cada pe vechiul prop in loc sa lase un gol.
##
## Inaltimea se scaleaza SEPARAT de amprenta (`h`), si asta e ce da varietate
## reala: aceeasi silueta la 0.8 si la 1.35 pe verticala citeste ca doua stanci
## diferite, gratis. Textura NU se intinde odata cu ea — clasa de roca e
## triplanara in spatiul LUMII, deci straturile raman la scara lumii indiferent
## cum e scalata instanta. Fara asta, o stanca turtita ar avea straturi turtite
## si s-ar vedea imediat ca e aceeasi piesa reciclata.
static func _add_canyon_rock(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, picks: Array[String], collide: bool,
		h_min: float = 0.80, h_max: float = 1.30) -> bool:
	var name_pick: String = picks[rng.randi_range(0, picks.size() - 1)]
	var kept := _pick_from_glb(CANYON_PATH, name_pick)
	if kept == null:
		return false
	var s := rng.randf_range(0.85, 1.25)
	var h := rng.randf_range(h_min, h_max)
	var holder: Node3D
	if collide:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	parent.add_child(holder)
	holder.add_child(kept)
	kept.scale = Vector3(s, s * h, s)
	Palette.apply_rock_material(kept)
	if collide:
		# Cilindru, nu sfera: o stiva in trepte e mai inalta decat lata, iar o
		# sfera pe amprenta ei ar lasa varful fara coliziune sau ar umfla baza
		# cu metri de aer. Cotele din AABB-ul real, ca la restul decorului.
		var aabb := Track.model_aabb(kept)
		var cyl := CylinderShape3D.new()
		cyl.radius = maxf(maxf(aabb.size.x, aabb.size.z) * 0.40, 0.4)
		cyl.height = maxf(aabb.size.y, 0.5)
		var shape := CollisionShape3D.new()
		shape.shape = cyl
		shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
		holder.add_child(shape)
	holder.rotation.y = rng.randf_range(0.0, TAU)
	# Infipta putin in nisip: fusta de moloz din model ascunde linia de contact
	# doar daca stanca chiar intra in teren.
	holder.position = pos + Vector3.UP * -0.25
	return true


## O piesa marunta din desert_scatter.glb, FARA coliziune.
##
## Astea sunt cele mai numeroase de pe pista (peste 100), asa ca nu primesc corp
## fizic: sunt un MeshInstance3D pus direct sub container. Vizual strang drumul,
## fizic nu exista — vezi comentariul de la banda "hug".
static func _add_scatter(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	const PICKS := ["Bush_A", "Bush_B", "Pebbles_A", "Pebbles_B", "Grass_Tuft"]
	var name_pick: String = PICKS[rng.randi_range(0, PICKS.size() - 1)]
	var kept := _pick_from_glb("res://assets/models/desert_scatter.glb", name_pick)
	if kept == null:
		_add_dry_bush(parent, pos, rng, mat)
		return
	parent.add_child(kept)
	kept.position = pos + Vector3.UP * -0.15
	kept.rotation.y = rng.randf_range(0.0, TAU)
	# Supradimensionate cu ~70%: la scara reala (tufa de 60cm, pietricica de 30cm)
	# pur si simplu nu se vad de la inaltimea camerei, si banda lipita de drum
	# ramane goala. style_bible §2 cere oricum obiectele cu 10-20% peste scara —
	# aici mergem mai departe pentru ca astea sunt piesele care STRANG cadrul.
	kept.scale = Vector3.ONE * rng.randf_range(1.4, 2.1)
	Palette.apply_world_material(kept)
	# Doar ce are frunze se leagana. O pietricica scuturata de vant ar fi exact
	# genul de detaliu care strica iluzia in loc s-o construiasca.
	if name_pick.begins_with("Bush") or name_pick == "Grass_Tuft":
		var sway := parent.get_node_or_null(^"Sway") as SwayDriver
		if sway == null:
			sway = parent.get_parent().get_node_or_null(^"Sway") as SwayDriver
		if sway != null:
			sway.add_item(kept)


## Un grup de bolovani din rock_cluster.glb.
##
## Coliziunea, cand exista, e o SINGURA sfera pe grup — nu una per piatra.
## Falezele aduc deja ~130 de forme; aici nu mai cheltuim.
static func _add_cluster(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, picks: Array, collide: bool,
		mat: Callable) -> void:
	var name_pick: String = picks[rng.randi_range(0, picks.size() - 1)]
	var kept := _pick_from_glb("res://assets/models/rock_cluster.glb", name_pick)
	if kept == null:
		_add_glb_rock(parent, pos, rng, mat)
		return
	var s := rng.randf_range(0.9, 1.3)
	if not collide:
		parent.add_child(kept)
		kept.position = pos + Vector3.UP * -0.2
		kept.rotation.y = rng.randf_range(0.0, TAU)
		kept.scale = Vector3.ONE * s
		Palette.apply_rock_material(kept)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.add_child(kept)
	kept.scale = Vector3.ONE * s
	Palette.apply_rock_material(kept)
	# Raza din AABB-ul real, nu dintr-un tabel: regenerezi GLB-ul cu alte cote si
	# coliziunea le urmeaza singura.
	var mi := _first_mesh(kept)
	var radius := 1.2 * s
	var height := 2.0 * s
	if mi != null and mi.mesh != null:
		var aabb := mi.mesh.get_aabb()
		radius = maxf(aabb.size.x, aabb.size.z) * 0.38 * s
		height = aabb.size.y * s
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(radius, 0.4)
	shape.shape = sphere
	shape.position = Vector3.UP * height * 0.42
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.2


## Instantiaza un GLB, pastreaza un singur nod si anuleaza offsetul lui din
## fisier (variantele sunt exportate una langa alta pentru vizualizare).
static func _pick_from_glb(path: String, node_name: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var container := (load(path) as PackedScene).instantiate() as Node3D
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == node_name:
			kept = child
		else:
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var found := _first_mesh(c)
		if found != null:
			return found
	return null


static func _add_tree(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	var tree := StaticBody3D.new()
	parent.add_child(tree)
	tree.position = pos + Vector3.UP * -0.3 # din iarba
	var scale_factor := rng.randf_range(0.8, 1.5)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 1.4 * scale_factor
	# CylinderMesh implicit are 64 de laturi si 4 inele. Un trunchi de copac
	# low-poly n-are nevoie de mai mult de 8 laturi si un inel.
	trunk_mesh.radial_segments = 8
	trunk_mesh.rings = 1
	trunk.mesh = trunk_mesh
	trunk.position = Vector3.UP * 0.7 * scale_factor
	trunk.material_override = mat.call(Color(0.45, 0.3, 0.18))
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0 # con
	crown_mesh.bottom_radius = 1.6 * scale_factor
	crown_mesh.height = 3.2 * scale_factor
	crown_mesh.radial_segments = 9 # numar impar: silueta nu iese simetrica
	crown_mesh.rings = 1
	crown.mesh = crown_mesh
	crown.position = Vector3.UP * (1.4 * scale_factor + 1.6 * scale_factor)
	# verde in 4 trepte: padurea are 4 materiale de coroana, nu unul per copac
	var green := 0.45 + float(rng.randi_range(0, 3)) / 3.0 * 0.20
	crown.material_override = mat.call(Color(0.2, green, 0.22))
	tree.add_child(crown)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 2.5
	shape.shape = cyl
	shape.position = Vector3.UP * 1.25
	tree.add_child(shape)


static func _add_rock(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	var rock := StaticBody3D.new()
	parent.add_child(rock)
	rock.position = pos + Vector3.UP * -0.2
	rock.rotation.y = rng.randf_range(0.0, TAU)
	var size := rng.randf_range(0.8, 2.2)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size * 0.7, size * 0.8)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3.UP * size * 0.3
	mesh_inst.rotation.z = rng.randf_range(-0.2, 0.2)
	mesh_inst.material_override = mat.call(Color(0.55, 0.55, 0.58))
	rock.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(size, size, size * 0.8)
	shape.shape = col_box
	shape.position = Vector3.UP * size * 0.3
	rock.add_child(shape)


## Cactus saguaro din cactus.glb (Blender): trei siluete distincte — fara brate,
## un brat, doua brate — cu coliziune pe trunchi. Modelul aduce UV-uri catre
## slotul de paleta si AO copt in vertex colors; ii inlocuim materialul cu cel
## UNIC al lumii, deci cactusii se grupeaza cu restul decorului in foarte putine
## draw call-uri (vezi docs/blender_export.md).
##
## Variatia NU mai vine din culoare: paleta are un singur verde, prin constructie
## — asta e chiar scopul atlasului. Vine din silueta, rotatie si o scalare mica.
## Inaltimile din model (2.85 / 3.50 / 4.40 m) sunt deja in intervalul cerut de
## style_bible §2, asa ca nu le scalam agresiv — altfel ies din interval.
static func _add_cactus(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	if not ResourceLoader.exists("res://assets/models/cactus.glb"):
		_add_dry_bush(parent, pos, rng, mat)
		return
	var container := (load("res://assets/models/cactus.glb") as PackedScene) \
		.instantiate() as Node3D
	var picks: Array[String] = ["Cactus_A", "Cactus_B", "Cactus_C"]
	var keep_name: String = picks[rng.randi_range(0, picks.size() - 1)]
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == keep_name:
			kept = child
		else:
			child.queue_free()
	if kept == null:
		container.queue_free()
		_add_dry_bush(parent, pos, rng, mat)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	# Banda e ingusta intentionat: variantele acopera deja 2.85-4.40 m, iar
	# style_bible §2 cere 2.8-4.5. O scalare mai generoasa scoate exemplarele
	# extreme din interval — masurat cu tools/probe_decor.gd: 0.92 -> 2.63 m,
	# 0.98 -> 2.79 m (sub prag), 1.03 -> 4.53 m (peste prag).
	# Variatia vine din silueta si rotatie, nu din scara.
	var s := rng.randf_range(0.99, 1.02)
	container.scale = Vector3.ONE * s
	container.position = -kept.position * s # variantele sunt exportate in origine
	body.add_child(container)
	Palette.apply_world_material(container)
	# Inaltimea se citeste din model: regenerezi GLB-ul cu alte cote si coliziunea
	# o urmeaza singura, fara tabel de inaltimi hardcodat.
	var h := 3.2
	var mi := kept as MeshInstance3D
	if mi != null and mi.mesh != null:
		h = mi.mesh.get_aabb().size.y * s
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.34
	cyl.height = h
	shape.shape = cyl
	shape.position = Vector3.UP * h * 0.5
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.3


static func _add_glb_rock(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	if not ResourceLoader.exists("res://assets/models/rocks.glb"):
		_add_rock(parent, pos, rng, mat)
		return
	var container := (load("res://assets/models/rocks.glb") as PackedScene) \
		.instantiate() as Node3D
	var picks: Array[String] = ["rock_small", "rock_medium", "rock_large"]
	var keep_name: String = picks[rng.randi_range(0, 2)]
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == keep_name:
			kept = child
		else:
			child.queue_free()
	if kept == null:
		container.queue_free()
		_add_rock(parent, pos, rng, mat)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	var s := rng.randf_range(0.55, 0.85)
	container.scale = Vector3.ONE * s
	container.position = -kept.position * s # anuleaza asezarea "una langa alta"
	body.add_child(container)
	# Inaltimea din AABB, nu dintr-un tabel. Cele trei cifre scrise de mana
	# (2.0 / 3.5 / 5.0) se nimereau exacte, dar rocks.glb e un asset vechi fara
	# UV pe sloturi si urmeaza sa fie scos — cand se intampla, coliziunea nu
	# trebuie sa ramana potrivita pe geometria care a plecat.
	var h: float = 3.5 * s
	var mi_rock := _first_mesh(kept)
	if mi_rock != null and mi_rock.mesh != null:
		h = mi_rock.mesh.get_aabb().size.y * s
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = h * 0.45
	shape.shape = sphere
	shape.position = Vector3.UP * h * 0.4
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.3


## Tufa uscata: doar vizual, treci prin ea.
static func _add_dry_bush(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	var bush := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var r := rng.randf_range(0.4, 0.8)
	sphere.radius = r
	sphere.height = r
	# Implicit SphereMesh e 64x32 = 4224 triunghiuri — pentru o tufa de 40cm,
	# adica geometria unei planete pe ceva cat o roata. La 8x4 ramane rotunda
	# la orice viteza de trecere si costa 64.
	sphere.radial_segments = 8
	sphere.rings = 4
	bush.mesh = sphere
	bush.position = pos + Vector3.UP * (r * 0.3 - 0.3)
	# Slotul de vegetatie uscata din paleta, in 3 trepte de nuanta (nu continuu,
	# altfel fiecare tufa ar cere material propriu).
	var tint := float(rng.randi_range(0, 2)) / 2.0 * 0.18
	bush.material_override = mat.call(
		Palette.color(Palette.DRY_VEGETATION).lightened(tint))
	parent.add_child(bush)
