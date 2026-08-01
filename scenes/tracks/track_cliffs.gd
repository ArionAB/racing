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


## Construieste falezele si le intoarce sub un singur nod.
##
## `landmarks` are formatul din [code]Track._landmark_spots()[/code]:
## (fractie 0..1, parte ±1, id-model).
static func build(sampler: TrackSideSampler, theme: String, seed_value: int,
		landmarks: Array[Vector3]) -> Node3D:
	var root := Node3D.new()
	root.name = "Cliffs"
	if theme != "desert" or not ResourceLoader.exists(MODEL_PATH):
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
		root.add_child(body)

		for spec in sampler.sample_edge(SPACING, OFFSET_OUTER):
			if spec.side_sign != side_sign:
				continue
			var d := spec.frac * total
			if not TrackSideSampler.in_segments(d, segments):
				continue
			if _near_landmark(d, total, clear_at):
				continue
			if _skip_slot(spec):
				continue
			_place(root, body, scene, spec, rng)
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
		spec: TrackDecorSpec, rng: RandomNumberGenerator) -> void:
	var wanted := _wanted_height(spec, rng)
	var pick := _best_variant(wanted)
	var model := _extract(scene, pick["node"])
	if model == null:
		return

	var scale_factor: float = clampf(wanted / float(pick["height"]),
		1.0 - SCALE_LIMIT, 1.0 + SCALE_LIMIT)
	# Scara in 4 trepte, nu continua: altfel fiecare sectiune ar fi un mesh unic
	# si s-ar pierde gruparea in putine draw call-uri.
	scale_factor = snappedf(scale_factor, 2.0 * SCALE_LIMIT / 3.0)

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
	pos.y -= SINK

	# Orientarea se calculeaza o data si se aplica AMANDURORA: nodului vizual si
	# formei de coliziune. Asa nu pot ajunge sa se contrazica.
	var basis := Basis.looking_at(-spec.normal_out, Vector3.UP)
	var xform := Transform3D(basis.scaled(Vector3.ONE * scale_factor), pos)

	var holder := Node3D.new()
	root.add_child(holder)
	holder.transform = xform
	holder.add_child(model)
	# Inclinarea de "asezat de mana" sta DOAR pe model, nu pe holder: un corp de
	# coliziune inclinat creeaza o pana intre sectiuni vecine, exact felul de colt
	# in care se intepeneste o masina.
	model.rotation = Vector3(
		rng.randf_range(-0.10, 0.10), 0.0, rng.randf_range(-0.10, 0.10))
	Palette.apply_world_material(holder)

	_add_collision(body, pick["node"], scene, xform)


## Inaltimea dorita la fractia asta: doua valuri suprapuse, plus o variatie in
## trepte. Canionul respira in loc sa fie un tunel uniform.
##
## Doua frecvente, nu una: cu un singur sinus lent, pereti vecini ies aproape la
## fel de inalti si peisajul citeste ca un zid continuu — verificat din vederea
## soferului. Al doilea val, mai rapid, rupe linia de sus.
static func _wanted_height(spec: TrackDecorSpec,
		rng: RandomNumberGenerator) -> float:
	var slow := sin(spec.frac * TAU * 3.7) * 2.2
	var fast := sin(spec.frac * TAU * 11.3) * 1.4
	var step := float(rng.randi_range(0, 2)) * 0.9
	var h := 8.0 + slow + fast + step
	# In apexul unui viraj, peretele scade: altfel nu vezi iesirea din curba.
	if spec.is_apex:
		h = minf(h, 7.0)
	return clampf(h, 6.5, 11.5)


## Se sare complet peste slotul asta? Un perete neintrerupt de 1200m obose ochiul
## si ascunde reperele de la orizont. Golurile lasa sa se vada butte-urile si dau
## senzatia ca soseaua IESE din canion si intra iar in el.
static func _skip_slot(spec: TrackDecorSpec) -> bool:
	# ~18% din traseu ramane deschis, in ferestre lungi (nu gauri izolate, care
	# ar arata ca sectiuni lipsa).
	return sin(spec.frac * TAU * 5.1 + spec.side_sign * 1.7) > 0.72


static func _best_variant(height: float) -> Dictionary:
	var best: Dictionary = VARIANTS[0]
	var best_delta := INF
	for v in VARIANTS:
		var delta: float = absf(float(v["height"]) - height)
		if delta < best_delta:
			best_delta = delta
			best = v
	return best


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
