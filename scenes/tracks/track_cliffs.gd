class_name TrackCliffs
extends RefCounted
## Peretii de canion de pe marginea soselei.
##
## Inlocuiesc gardul rosu de 1.3m: pe tema desert, falezele fac SI vizualul, SI
## coliziunea. Se aseaza pe aceleasi segmente pe care vechea regula de perete
## cerea gard — exterior mereu, interior doar unde soseaua e inaltata — citite
## din [method TrackSideSampler.wall_segments], ca sa nu existe doua definitii
## care pot diverge.
##
## Coliziunea e o cutie convexa per sectiune, nu un trimesh: vezi _add_collision.

const MODEL_PATH: String = "res://assets/models/cliff_wall.glb"

## Pasul de asezare. Sectiunile au 15m latime, deci se suprapun 1m. Suprapunerea
## nu e cosmetica: doua cutii de coliziune care se ating exact la muchie lasa o
## fisura in care Jolt agata masina.
const SPACING: float = 14.0
## Distanta de la marginea asfaltului pana la fata falezei, pe portiunile drepte.
const OFFSET_OUTER: float = 1.2
## Cat se retrag falezele pe EXTERIORUL virajelor.
##
## Masurat: cu 1.2m peste tot, ecartul dintre prima si ultima masina cadea de la
## 0.42 tururi la 0.03 — nimeni nu mai putea depasi. Cauza nu era coliziunea (zero
## blocaje, zero repuneri), ci ca linia larga de depasire dispare: masina rapida
## ramanea prinsa in pluton, cu de doua ori mai multe imbranceli si de patru ori
## mai putine atingeri de perete decat inainte.
##
## Exteriorul virajului e exact locul unde se depaseste, deci acolo peretele se
## trage inapoi. Vizual nu se pierde nimic: la viteza, un perete la 5m si unul la
## 1.2m arata la fel de aproape.
const OFFSET_CORNER: float = 5.0
## Pe interior, unde soseaua e inaltata, falezele stau mai retrase: acolo trec
## masinile care taie viraful, si un perete la 1.2m ar transforma scurtatura in
## capcana.
const OFFSET_INNER: float = 4.5
## Cat se ingroapa fiecare sectiune in nisip. Fara asta se vede linia de contact
## si se rupe iluzia de stanca iesita din sol.
const SINK: float = 0.6
## Raza libera in jurul unui landmark hero (style_bible §7: teren gol in fata
## landmark-urilor majore). Turnul de apa de 9.5m langa o faleza de 11m dispare.
const LANDMARK_CLEAR: float = 25.0

## Variantele din GLB, cu inaltimea lor nominala. Godot alege varianta cea mai
## apropiata de inaltimea ceruta si scaleaza cel mult ±SCALE_LIMIT.
const VARIANTS := [
	{"node": "Cliff_A", "height": 6.5},
	{"node": "Cliff_B", "height": 8.0},
	{"node": "Cliff_C", "height": 9.5},
	{"node": "Cliff_D", "height": 11.0},
	{"node": "Cliff_E", "height": 7.5},
	{"node": "Cliff_F", "height": 10.0},
]
## Peste atat se vede intinderea straturilor de roca.
const SCALE_LIMIT: float = 0.18
## Cat de departe de inaltimea ceruta mai intra o varianta in bazinul de alegere.
const VARIANT_TOLERANCE: float = 0.22


## Construieste falezele si le intoarce sub un singur nod.
##
## `landmarks` are formatul din [code]Track._landmark_spots()[/code]:
## (fractie 0..1, parte ±1, id-model).
## `enabled` vine din tema pistei (Track.themes(), cheia "cliffs"). Inainte era
## `theme != "desert"` — adica falezele de canion erau legate de numele unei
## piste, nu de o proprietate a lumii. Insula are promontoriu de zid gusuku, nu
## canion, deci ii trebuia un "nu" care sa nu insemne "nu sunt desert".
static func build(sampler: TrackSideSampler, enabled: bool, seed_value: int,
		landmarks: Array[Vector3]) -> Node3D:
	var root := Node3D.new()
	root.name = "Cliffs"
	if not enabled or not ResourceLoader.exists(MODEL_PATH):
		return root

	var scene := load(MODEL_PATH) as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 4242
	var total := sampler.total_length()
	if total <= 0.0:
		return root

	# Distantele (in metri pe traseu) in jurul carora nu se pun faleze.
	var clear_at: Array[float] = []
	for lm in landmarks:
		clear_at.append(lm.x * total)

	for side_sign: float in [-1.0, 1.0]:
		var segments := sampler.wall_segments(side_sign)
		if segments.is_empty():
			continue
		# UN singur corp static per latura, cu multe forme copil. Jolt trateaza
		# asta mult mai bine decat ~70 de corpuri separate.
		var body := StaticBody3D.new()
		body.name = "CliffBody%s" % ("L" if side_sign < 0.0 else "R")
		body.add_to_group("cliffs")
		# Layer 8: "ce n-are voie sa stea intre camera si masina". Camera face
		# raycast DOAR pe layer-ul asta — pe layer-ul implicit ar lovi popice,
		# mingea si celelalte masini, si fiecare depasire ar smuci cadrul.
		body.collision_layer |= Track.CAMERA_BLOCKER_LAYER
		root.add_child(body)

		for spec in sampler.sample_edge(SPACING, OFFSET_OUTER):
			if spec.side_sign != side_sign:
				continue
			var d := spec.frac * total
			if not TrackSideSampler.in_segments(d, segments):
				continue
			if _near_landmark(d, total, clear_at):
				continue
			# O rapa cu un zid in fata nu se vede, deci nu e nici drama, nici
			# avertisment — e doar o groapa in care cazi fara sa intelegi de ce.
			# Aici peretele se deschide si prapastia devine lizibila de departe.
			if spec.is_ravine:
				continue
			if _skip_slot(spec):
				continue
			_place(root, body, scene, sampler, spec, rng)
	return root


## Distanta `d` cade prea aproape de un landmark? Comparatia e circulara: un
## landmark la fractia 0.02 trebuie sa protejeze si sfarsitul turului.
static func _near_landmark(d: float, total: float,
		clear_at: Array[float]) -> bool:
	for c in clear_at:
		var delta := absf(d - c)
		delta = minf(delta, total - delta)
		if delta < LANDMARK_CLEAR:
			return true
	return false


static func _place(root: Node3D, body: StaticBody3D, scene: PackedScene,
		sampler: TrackSideSampler,
		spec: TrackDecorSpec, rng: RandomNumberGenerator) -> void:
	var wanted := _wanted_height(spec, rng)
	var pick := _variant_for(wanted, rng)
	var model := _extract(scene, pick["node"])
	if model == null:
		return

	# Scara CONTINUA. Cuantizarea de dinainte se justifica prin "altfel fiecare
	# sectiune ar fi un mesh unic", ceea ce e fals: scara uniforma a unui nod nu
	# duplica niciodata o resursa Mesh. Gruparea in draw call-uri vine din
	# materialul partajat, nu din scara. Deci trepte in plus, gratis.
	var scale_factor: float = clampf(wanted / float(pick["height"]),
		1.0 - SCALE_LIMIT, 1.0 + SCALE_LIMIT)

	# Originea modelului e centrata pe adancime, deci jumatate din faleza sta in
	# fata originii. Fara corectia asta, o sectiune adanca de 6m aterizeaza cu
	# 3m PESTE asfalt. Se citeste din AABB, nu dintr-un tabel: regenerezi GLB-ul
	# cu alte cote si asezarea le urmeaza singura.
	var half_depth := _half_depth(model) * scale_factor
	# Cat de departe sta peretele. Retragerea se aplica DOAR unde se depaseste —
	# aplicata peste tot (prima incercare), lasa un camp gol de nisip intre drum
	# si stanca pe portiunile drepte, si canionul se pierde. Vazut in vederea
	# soferului la frac=0.20; la frac=0.55, in viraj, retragerea e exact potrivita.
	var extra := 0.0
	if not spec.is_exterior:
		extra = OFFSET_INNER - OFFSET_OUTER
	elif spec.is_apex or spec.is_braking:
		# Viraj strans sau zona de franare: aici chiar se depaseste, deci cel mai
		# mult loc (style_bible §7 cere 8m liberi la franare).
		extra = OFFSET_CORNER + 2.0 - OFFSET_OUTER
	var pos := spec.position + spec.normal_out * (extra + half_depth)
	# Re-esantionam cota: slotul s-a mutat lateral pana la ~7 m fata de unde a
	# fost masurat, iar pe o panta de 12% asta inseamna aproape un metru de
	# diferenta — destul cat sa se vada baza falezei plutind sau ingropata.
	pos.y = sampler.ground_y(pos.x, pos.z) - SINK

	# Orientarea se calculeaza o data si se aplica AMANDURORA: nodului vizual si
	# formei de coliziune. Asa nu pot ajunge sa se contrazica.
	var basis := Basis.looking_at(-spec.normal_out, Vector3.UP)
	var xform := Transform3D(basis.scaled(Vector3.ONE * scale_factor), pos)

	var holder := Node3D.new()
	root.add_child(holder)
	holder.transform = xform
	holder.add_child(model)
	# Oglindirea dubleaza numarul de siluete distincte cu 6 variante de GLB si
	# zero triunghiuri in plus. Cere materialul geaman cu CULL_FRONT, altfel
	# stanca se randeaza pe dos. Coliziunea NU se oglindeste: e o cutie aproape
	# simetrica, iar oglindirea ei poate doar sa creeze pene intre sectiuni.
	var mirror := rng.randf() < 0.5
	if mirror:
		model.scale = Vector3(-1.0, 1.0, 1.0)
	# Inclinarea de "asezat de mana" sta DOAR pe model, nu pe holder: un corp de
	# coliziune inclinat creeaza o pana intre sectiuni vecine, exact felul de colt
	# in care se intepeneste o masina.
	#
	# Yaw-ul era hardcodat ZERO, deci fiecare faleza prezenta soferului exact
	# aceeasi fata. Plafon dur la ±0.10 rad: o sectiune de 15 m isi deplaseaza
	# capatul cu 0.75 m la unghiul asta, iar suprapunerea dintre sectiuni e de
	# doar 1 m. Mai mult deschide fisuri — exact ce prinde sonda --mode=cliff.
	model.rotation = Vector3(
		rng.randf_range(-0.07, 0.07),
		rng.randf_range(-0.10, 0.10),
		rng.randf_range(-0.07, 0.07))
	Palette.apply_world_material(holder, mirror)

	_add_collision(body, pick["node"], scene, xform)


## Inaltimea dorita la fractia asta: doua valuri suprapuse, plus o variatie in
## trepte. Canionul respira in loc sa fie un tunel uniform.
##
## Doua frecvente, nu una: cu un singur sinus lent, pereti vecini ies aproape la
## fel de inalti si peisajul citeste ca un zid continuu — verificat din vederea
## soferului. Al doilea val, mai rapid, rupe linia de sus.
static func _wanted_height(spec: TrackDecorSpec,
		rng: RandomNumberGenerator) -> float:
	# Frecventele erau 3.7 si 11.3, cu raportul 3.05 — aproape intreg, deci se
	# sincronizau si aceeasi succesiune de siluete revenea de ~3.7 ori pe tur.
	# 2.3 si 7.9 dau raportul 3.43, care nu se inchide intr-un tur.
	var slow := sin(spec.frac * TAU * 2.3) * 2.2
	var fast := sin(spec.frac * TAU * 7.9) * 1.4
	# Termen defazat PER LATURA: fara el, cei doi pereti respirau la unison.
	var lean := sin(spec.frac * TAU * 1.3 + spec.side_sign * 2.1) * 1.6
	var step := float(rng.randi_range(0, 3)) * 0.75
	var h := 8.0 + slow + fast + lean + step
	# In apexul unui viraj, peretele scade: altfel nu vezi iesirea din curba.
	#
	# Plafonul era fix 7.0, exact la mijloc intre Cliff_A (6.5) si Cliff_E (7.5).
	# Cum alegerea variantei folosea `<` strict, A castiga MEREU — fiecare apex de
	# pe pista primea identic aceeasi stanca.
	if spec.is_apex:
		h = minf(h, rng.randf_range(6.6, 7.9))
	return clampf(h, 6.5, 11.5)


## Se sare complet peste slotul asta? Un perete neintrerupt de 1200m obose ochiul
## si ascunde reperele de la orizont. Golurile lasa sa se vada butte-urile si dau
## senzatia ca soseaua IESE din canion si intra iar in el.
static func _skip_slot(spec: TrackDecorSpec) -> bool:
	# ~18% din traseu ramane deschis, in ferestre lungi (nu gauri izolate, care
	# ar arata ca sectiuni lipsa).
	# side_sign era doar o defazare a ACELEIASI sinusoide, deci ambele laturi se
	# deschideau in acelasi loc. Frecvente diferite per latura: tiparul nu se mai
	# repeta intr-un tur.
	var f := 5.1 if spec.side_sign < 0.0 else 3.9
	var ph := 1.7 if spec.side_sign < 0.0 else 4.4
	return sin(spec.frac * TAU * f + ph) > 0.72


## Alege o varianta din bazinul celor care incap in inaltimea ceruta.
##
## Era argmin pur: pentru fiecare inaltime iesea MEREU aceeasi stanca, deci cele
## 6 variante se roteau dupa un tipar previzibil. Cu un bazin de toleranta ies
## de obicei 2-4 candidate, si zarul decide — aceeasi silueta de perete, alta
## piatra de fiecare data.
static func _variant_for(height: float, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = []
	for v in VARIANTS:
		if absf(float(v["height"]) - height) <= height * VARIANT_TOLERANCE:
			pool.append(v)
	if pool.is_empty():
		# Nimic in toleranta (inaltimi extreme): cade inapoi pe cel mai apropiat.
		var best: Dictionary = VARIANTS[0]
		var best_delta := INF
		for v in VARIANTS:
			var delta: float = absf(float(v["height"]) - height)
			if delta < best_delta:
				best_delta = delta
				best = v
		return best
	return pool[rng.randi_range(0, pool.size() - 1)]


## Scoate o singura varianta din GLB si anuleaza offsetul ei din fisier
## (variantele sunt exportate toate in origine, dar importul poate pastra
## pozitii). Restul nodurilor se elibereaza.
static func _extract(scene: PackedScene, node_name: String) -> Node3D:
	var container := scene.instantiate() as Node3D
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


## Cutie convexa per sectiune, construita din nodul `Cliff_X_col` din GLB.
##
## Nu un trimesh din mesh-ul vizual: ar fi ~180 de triunghiuri de coliziune per
## sectiune, ori ~70 de sectiuni, si fiecare crapatura din silueta ar deveni un
## colt in care se agata masina. Cutia urmareste doar fata dinspre drum, unde se
## produce de fapt contactul.
static func _add_collision(body: StaticBody3D, node_name: String,
		scene: PackedScene, xform: Transform3D) -> void:
	var col_source := _extract(scene, node_name + "_col")
	if col_source == null:
		return
	var mi := _first_mesh(col_source)
	if mi == null:
		col_source.queue_free()
		return
	var shape := CollisionShape3D.new()
	shape.shape = mi.mesh.create_convex_shape()
	# Acelasi transform ca nodul vizual — mai putin inclinarea de pe X/Z, care sta
	# pe copilul-model, nu aici.
	body.add_child(shape)
	shape.transform = xform
	col_source.queue_free()


## Jumatate din adancimea modelului, in metri. Modelele sunt exportate cu fata
## dinspre drum pe -Z (dupa conversia Y-up a lui Godot), centrate pe axa aia.
static func _half_depth(model: Node3D) -> float:
	var mi := _first_mesh(model)
	if mi == null or mi.mesh == null:
		return 3.0
	return mi.mesh.get_aabb().size.z * 0.5


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var found := _first_mesh(c)
		if found != null:
			return found
	return null
