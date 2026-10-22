extends RefCounted
## Registru de vegetatie MICA pe care masina o strabate (feel_checklist:
## soft-hazards): tufe, ferigi, salvie, hibiscus — tot ce n-are coliziune si
## pe care azi treci ca printr-o fantoma.
##
## DE UNDE IA POZITIILE. Vegetatia pistelor nu e noduri: generatoarele o coc
## in MultiMeshInstance3D-uri pe celule (TrackDecorBatch), numite dupa model
## (`Bush_A_0_-`, `Veg_Fern_Cluster_-1_-`, `Sagebrush_Foliage`...). Registrul
## cauta chunk-urile al caror nume e de tufa, citeste transformarile
## instantelor O DATA (la prima intrebare dintr-o cursa) si le pune intr-o
## grila de 6 m. Nimic nu se schimba in generatoare si nici in decor: pistele
## fara astfel de chunk-uri raman cu registrul gol (cost zero).
##
## CE NU INTRA, cu buna stiinta: iarba densa (`Grass*` din TrackGrass si din
## zonele de pajiste — mii de fire pe metru, ar insemna un nor continuu), si
## copacii/stancile, care au coliziune proprie. Smocurile mici de iarba
## (`*Tuft*`) intra.
##
## HEADLESS: serverul de randare fara fereastra intoarce transformari ZERO
## pentru orice instanta de MultiMesh (memoria multimesh-masuratoare-moarta).
## Cand toate pozitiile citite sunt zero, chunk-ul e sarit, deci in `--headless`
## registrul ramane gol si nicio sonda de cursa nu e influentata. Pentru sonde,
## `add_bush` pune tufe direct.

const CELL_M: float = 6.0
const NAME_RE: String = "(?i)bush|shrub|scrub|sage|brush|fern|hibiscus|caper|ginestra|cane|tuft|broadleaf|karikomi|jneapan"
## Latura tufei = jumatate din cutia mesh-ului, cu un factor: cutia include
## frunzele rare de la margine.
const RADIUS_FRACTION: float = 0.7
const RADIUS_MIN: float = 0.35
const RADIUS_MAX: float = 1.6
## Cat de lat e „corpul" care atinge tufa: o masina trece cu rotile la ~0.9 m
## de axa, deci contactul incepe la raza tufei + asta.
const CAR_REACH_M: float = 0.7

## root.get_instance_id() -> {cells: Dictionary, count: int, scanned: bool}
static var _cache: Dictionary = {}
static var _regex: RegEx = null


static func _entry(root: Node3D) -> Dictionary:
	var id := root.get_instance_id()
	if not _cache.has(id):
		# Curata intrarile radacinilor disparute (alta pista, alta cursa).
		for k: int in _cache.keys():
			if not is_instance_id_valid(k):
				_cache.erase(k)
		_cache[id] = {"cells": {}, "count": 0, "scanned": false}
	return _cache[id]


static func count(root: Node3D) -> int:
	return int(_entry(root)["count"]) if root != null else 0


static func is_scanned(root: Node3D) -> bool:
	return root != null and bool(_entry(root)["scanned"])


static func clear(root: Node3D) -> void:
	_cache.erase(root.get_instance_id())


## Pune o tufa direct (sonde, decor facut de mana in cod).
static func add_bush(root: Node3D, pos: Vector3, radius: float = 1.0, height: float = 1.2) -> void:
	var e := _entry(root)
	var cell := Vector2i(floori(pos.x / CELL_M), floori(pos.z / CELL_M))
	var arr: PackedFloat32Array = (e["cells"] as Dictionary).get(cell, PackedFloat32Array())
	arr.append_array(PackedFloat32Array([pos.x, pos.y, pos.z, radius, height]))
	(e["cells"] as Dictionary)[cell] = arr
	e["count"] = int(e["count"]) + 1


## Citeste chunk-urile de tufe din subarborele `root`. O singura data pe
## radacina (`force` o repeta). Intoarce numarul de tufe gasite.
static func scan(root: Node3D, force: bool = false) -> int:
	var e := _entry(root)
	if bool(e["scanned"]) and not force:
		return int(e["count"])
	if _regex == null:
		_regex = RegEx.create_from_string(NAME_RE)
	e["scanned"] = true
	_walk(root, root)
	return int(e["count"])


## Numele unui chunk e de tufa? (vezi antetul: iarba densa nu, smocurile da.)
static func is_bush_name(nm: String) -> bool:
	if _regex == null:
		_regex = RegEx.create_from_string(NAME_RE)
	var low := nm.to_lower()
	if low.begins_with("grass") and not low.contains("tuft"):
		return false
	return _regex.search(nm) != null


static func _walk(root: Node3D, n: Node) -> void:
	if n is MultiMeshInstance3D:
		var mmi := n as MultiMeshInstance3D
		if is_bush_name(String(mmi.name)):
			_read_chunk(root, mmi)
		return
	for c in n.get_children():
		_walk(root, c)


static func _read_chunk(root: Node3D, mmi: MultiMeshInstance3D) -> void:
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null or mm.instance_count <= 0:
		return
	var box := mm.mesh.get_aabb()
	var n := mm.instance_count
	# Masuratoare moarta (vezi antetul): primele pozitii toate zero.
	var live := false
	for i in mini(n, 4):
		if mm.get_instance_transform(i).origin != Vector3.ZERO:
			live = true
			break
	if not live:
		return
	var g := mmi.global_transform
	for i in n:
		var xf := mm.get_instance_transform(i)
		var s := xf.basis.get_scale()
		var r := clampf(0.5 * maxf(box.size.x * s.x, box.size.z * s.z) * RADIUS_FRACTION,
			RADIUS_MIN, RADIUS_MAX)
		add_bush(root, g * xf.origin, r, maxf(box.end.y * s.y, 0.3))


## Cat de adanc e `pos` intr-o tufa: 0 = in afara, 1 = in centrul ei. Doar tufele
## cu baza la inaltimea punctului (nu o tufa de pe un deal vecin).
static func depth_at(root: Node3D, pos: Vector3) -> float:
	var e := _entry(root)
	if int(e["count"]) == 0:
		return 0.0
	var cells: Dictionary = e["cells"]
	var cx := floori(pos.x / CELL_M)
	var cz := floori(pos.z / CELL_M)
	var best := 0.0
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var arr: PackedFloat32Array = cells.get(Vector2i(cx + dx, cz + dz), PackedFloat32Array())
			var i := 0
			while i < arr.size():
				var ex := pos.x - arr[i]
				var ez := pos.z - arr[i + 2]
				var reach: float = arr[i + 3] + CAR_REACH_M
				if ex * ex + ez * ez < reach * reach:
					var dy := pos.y - arr[i + 1]
					if dy > -0.6 and dy < arr[i + 4] + 0.3:
						best = maxf(best, 1.0 - sqrt(ex * ex + ez * ez) / reach)
				i += 5
	return best
