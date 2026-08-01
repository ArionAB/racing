class_name TrackDecor
extends RefCounted
## Decorul imprastiat in jurul soselei: pietre, cactusi, mese, copaci.
##
## Extras din [code]track.gd[/code] ca sa se poata lucra in paralel pe decor si
## pe restul pistei fara conflicte in acelasi fisier. Comportamentul e deocamdata
## IDENTIC cu cel dinainte (aceeasi esantionare prin respingere, acelasi seed,
## aceleasi cote) — rescrierea pe benzi paralele cu drumul vine separat.
##
## Materialele NU se creeaza aici: `mat_provider` e cache-ul de culoare din
## [code]track.gd[/code] ([code]_flat_material[/code]). Daca decorul si-ar face
## materiale proprii, garda de draw call-uri din [code]tools/probe_decor.gd[/code]
## ar deveni oarba exact acolo unde conteaza cel mai mult.

## Cate prop-uri se incearca si cate se accepta.
const MAX_PLACED: int = 80
const MAX_ATTEMPTS: int = 400
## Banda in care se accepta un prop, ca distanta fata de axa soselei.
const NEAR_MARGIN: float = 8.0
const FAR_LIMIT: float = 90.0


## Construieste tot decorul si il intoarce sub un singur nod.
##
## `mat_provider` = Callable(Color) -> StandardMaterial3D.
static func build(sampler: TrackSideSampler, theme: String, seed_value: int,
		mat_provider: Callable) -> Node3D:
	var root := Node3D.new()
	root.name = "Decor"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var n := sampler.point_count()
	if n == 0:
		return root
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
		var nearest := sampler.clearance_at(pos)
		if nearest < sampler.half_width() + NEAR_MARGIN or nearest > FAR_LIMIT:
			continue
		placed += 1
		if theme == "desert":
			# Provizoriu: castelul de nisip si galeata au iesit odata cu tema de
			# lada de nisip, iar cotele lor s-au redistribuit la piatra si mesa.
			var roll := rng.randf()
			if roll < 0.34:
				_add_cactus(root, pos, rng, mat_provider)
			elif roll < 0.60:
				_add_glb_rock(root, pos, rng, mat_provider)
			elif roll < 0.82:
				_add_mesa(root, pos, rng, mat_provider)
			else:
				_add_dry_bush(root, pos, rng, mat_provider)
		elif rng.randf() < 0.7:
			_add_tree(root, pos, rng, mat_provider)
		elif rng.randf() < 0.5:
			_add_glb_rock(root, pos, rng, mat_provider)
		else:
			_add_rock(root, pos, rng, mat_provider)
	return root


# ------------------------------------------------------------ prop-uri

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


## Mesa: lespezi de piatra rosiatica suprapuse, cu coliziune.
static func _add_mesa(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	var mesa := StaticBody3D.new()
	parent.add_child(mesa)
	mesa.position = pos + Vector3.UP * -0.2
	mesa.rotation.y = rng.randf_range(0.0, TAU)
	var base := rng.randf_range(1.6, 3.6)
	var levels := 2 + (1 if rng.randf() < 0.4 else 0)
	var y := 0.0
	for level in levels:
		var frac := 1.0 - float(level) * 0.28
		var slab := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(base * frac, base * 0.4, base * 0.85 * frac)
		slab.mesh = box
		y += base * 0.2
		slab.position = Vector3.UP * y
		y += base * 0.2
		# Culoare din paleta (rock_light), nu inventata: mesa e decor de desert,
		# deci intra sub aceleasi sloturi ca prop-urile din Blender. Lespezile de
		# sus sunt mai deschise — straturi de stanca, style_bible §3.
		slab.material_override = mat.call(
			Palette.color(Palette.ROCK_LIGHT).lightened(float(level) * 0.08))
		mesa.add_child(slab)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(base, base * 0.8, base * 0.85)
	shape.shape = col
	shape.position = Vector3.UP * base * 0.4
	mesa.add_child(shape)


## Bolovan de acvariu (Blender): rocks.glb are 3 mesh-uri separate,
## alegem una la intamplare si anulam offsetul ei din fisier.
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
	var heights := {"rock_small": 2.0, "rock_medium": 3.5, "rock_large": 5.0}
	var h: float = heights[keep_name] * s
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
