extends Node
## Sonda de POARTA pentru POI H: unde anume incape `main_gate` pe cornisa, si
## cat ramane liber fata de carosabil.
##
## Contractul e un GOL, deci se masoara ca gol, nu ca AABB (memoria
## cota-de-contract-se-masoara-ca-gol): se proiecteaza triunghiurile piesei pe
## planul (lateral, y) si se cauta banda libera continua in jurul axei, in
## fereastra de inaltime a masinii.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpHGate.tscn
##
## Tipareste, pentru fiecare fractie candidata: semi-latimea drumului acolo,
## golul liber al portii la scara 1, si cat musca poarta din carosabil de
## fiecare parte.

const TRACK := "res://scenes/tracks/Track15.tscn"
const GATE := "res://assets/models/machupicchu/structures/main_gate.glb"
## Ferestrele de inaltime pe care se masoara golul. Prima e cea care conteaza
## pentru gameplay: gabaritul masinii, de la 15 cm (sub prag) pana la 1,8 m
## (peste plafonul celei mai inalte caroserii). A doua e cea pe care s-a facut
## masuratoarea din inventar (pana sub buiandrug) — se pastreaza ca sa se vada
## DE CE cele doua cifre difera.
const WINDOWS := [Vector2(0.15, 1.80), Vector2(0.15, 5.80), Vector2(0.15, 0.60)]
const CELL := 0.01


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var gate_scene := load(GATE) as PackedScene
	var inst := gate_scene.instantiate()
	var mi := _find_mesh(inst)
	if mi == null:
		print("; NU am gasit mesh in main_gate.glb")
		get_tree().quit(1)
		return
	var arrs := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrs[Mesh.ARRAY_INDEX]
	var xf := mi.transform
	print("; main_gate: nod %s, %d vertecsi, %d indici, aabb %s" % [
		mi.name, verts.size(), idx.size(), str(mi.mesh.get_aabb())])

	# Golul liber pe axa locala X, per fereastra de inaltime: se rasterizeaza
	# ocuparea pe X si se cauta cea mai lata banda libera care contine x=0.
	var gap := 0.0
	for w: Vector2 in WINDOWS:
		var occupied := {}
		var n_tri := idx.size() / 3
		for t in n_tri:
			var a: Vector3 = xf * verts[idx[t * 3]]
			var b: Vector3 = xf * verts[idx[t * 3 + 1]]
			var c: Vector3 = xf * verts[idx[t * 3 + 2]]
			# Se sampleaza triunghiul dens si se marcheaza celulele de X ale
			# caror puncte cad in fereastra de inaltime.
			var steps := 40
			for i in range(steps + 1):
				for j in range(steps + 1 - i):
					var u := float(i) / float(steps)
					var v := float(j) / float(steps)
					var p := a * (1.0 - u - v) + b * u + c * v
					if p.y >= w.x and p.y <= w.y:
						occupied[int(floor(p.x / CELL))] = true
		var lo := 0
		while not occupied.has(lo - 1) and lo > -3000:
			lo -= 1
		var hi := 0
		while not occupied.has(hi + 1) and hi < 3000:
			hi += 1
		var gap_lo := float(lo) * CELL
		var gap_hi := float(hi + 1) * CELL
		print("; GOL LIBER in fereastra y=%.2f..%.2f: [%.3f, %.3f] = %.3f m" % [
			w.x, w.y, gap_lo, gap_hi, gap_hi - gap_lo])
		if w == WINDOWS[0]:
			gap = gap_hi - gap_lo
	var gap_hi := gap * 0.5
	var gap_lo := -gap * 0.5

	# Unde anume pe traseu: semi-latimea la fractii candidate.
	var n := track.baked.size()
	print("; frac    half   latime_drum  gol_poarta  muscatura/parte")
	var f := 0.955
	while f <= 0.975:
		var i := int(f * float(n)) % n
		var half: float = track.width_at_index(i)
		var road := 2.0 * half
		var bite := (road - (gap_hi - gap_lo)) * 0.5
		print("; %.4f  %5.2f  %10.2f  %10.3f  %+.3f" % [
			f, half, road, gap_hi - gap_lo, bite])
		f += 0.001
	get_tree().quit(0)


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for c in node.get_children():
		var r := _find_mesh(c)
		if r != null:
			return r
	return null
