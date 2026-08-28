extends SceneTree
## Sonda pentru COLIZIUNEA decorului manual: cine a primit corp, ce fel, si
## — singura intrebare care conteaza cu adevarat — daca vreun colizor a ajuns
## peste carosabil.
##
## Exista fiindca `world_prop.gd` construieste corpurile AUTOMAT, la rulare, si
## fara owner: nu se vad in .tscn, nu se vad in editor, si nu apar in nicio
## captura. Un zid invizibil peste sosea ar fi deci exact clasa de bug pe care
## n-o prinde nimic altceva.
##
## Testul NU e o socoteala pe cutii: pe un butte de 50 m orice masuratoare pe
## AABB raporteaza „in carosabil" fiindca jumatate din diagonala lui e mai lunga
## decat distanta pana la drum. Aici se plimba in schimb CHIAR corpul masinii
## (o cutie de latimea benzii de rulare, la inaltimea ei) pe linia soselei,
## din metru in metru, si se intreaba fizica pe cine atinge — adica exact
## intrebarea „pot sa conduc tot turul fara sa intru intr-un zid".
##
## Piesele prin care se TRECE (arcade, tuneluri, poarta de start) au colizor
## exact si stau peste sosea prin proiect; pe ele sonda verifica altceva —
## ca golul lor e liber la inaltimea masinii.
##
##   godot --headless --path . --script res://tools/probe_solid.gd
##   ... -- --track=10
##
## Cod de iesire 1 daca ceva atinge cutia de gabarit a masinii.

## Gabaritul plimbat pe traseu: latime de masina cu marja, inaltime de masina.
const CAR_WIDTH: float = 2.4
const CAR_HEIGHT: float = 1.4
const CAR_LENGTH: float = 4.0
## Pasul de esantionare pe traseu, in puncte coapte (~1 m intre ele).
const STEP: int = 2

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _fail: bool = false


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 20):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_solid: nu am gasit nicio pista")
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		if _index >= _paths.size():
			print("\nVERDICT: %s" % ("PESTE DRUM" if _fail else "OK"))
			quit(1 if _fail else 0)
			return true
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 4:
		return false # o tura de fizica, ca noile corpuri sa intre in spatiu
	_report(_paths[_index], _track)
	_track.queue_free()
	_track = null
	_index += 1
	return false


func _report(path: String, track: Node) -> void:
	var manual: Node3D = track.get_node_or_null("DecorManual")
	print("\n=== %s ===" % path.get_file())
	if manual == null:
		print("fara DecorManual")
		return
	var modes := {}
	var shapes := 0
	var bodies := _bodies(manual)
	for body in bodies:
		var mode: String = String(body.get_meta("mod_coliziune", "hull"))
		modes[mode] = int(modes.get(mode, 0)) + 1
		for c in body.get_children():
			if c is CollisionShape3D:
				shapes += 1
	var order: Array = modes.keys()
	order.sort()
	print("corpuri %d, forme %d — %s" % [bodies.size(), shapes,
		", ".join(order.map(func(k): return "%s %d" % [k, modes[k]]))])

	# --- gabaritul masinii, plimbat pe axa soselei -------------------------
	var space := root.world_3d.direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_WIDTH, CAR_HEIGHT, CAR_LENGTH)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var baked: PackedVector3Array = track.baked
	var n := baked.size()
	var hits := {}
	var i := 0
	while i < n:
		var here: Vector3 = baked[i]
		var ahead: Vector3 = baked[(i + 4) % n]
		var dir := (ahead - here)
		dir.y = 0.0
		if dir.length() < 0.01:
			i += STEP
			continue
		var xform := Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP),
			here + Vector3.UP * (CAR_HEIGHT * 0.5 + 0.15))
		query.transform = xform
		for hit in space.intersect_shape(query, 32):
			var col := hit["collider"] as Node
			if col == null or not String(col.name).ends_with("_col"):
				continue
			var frac: float = track.frac_at(i)
			if not hits.has(col.name):
				hits[col.name] = [frac, String(col.get_meta("mod_coliziune",
					"hull"))]
		i += STEP
	# NODUL DE TRAFIC e singurul decor din joc care sta PE sosea prin proiect
	# (brief chongqing.md §2 A: bulevardul blocat, cu o singura fanta). Sonda
	# asta plimba gabaritul pe AXUL soselei, deci il va gasi intotdeauna — si
	# are dreptate: pe ax chiar nu se trece. Intrebarea corecta pentru el nu e
	# „e liber axul", ci „exista blocaj SI o fanta trecabila", si pe aia o pune
	# `tools/probe_fanta.gd`. Se raporteaza deci separat, nu se ascunde.
	var blockade: Array = []
	var real: Array = []
	for name: String in hits.keys():
		if name.begins_with("masina_") or name.begins_with("autobuz_"):
			blockade.append(name)
		else:
			real.append(name)
	blockade.sort()
	real.sort()
	if not blockade.is_empty():
		print("nodul de trafic (pe sosea prin proiect — vezi probe_fanta): %s"
			% ", ".join(blockade))
	if real.is_empty():
		print("gabaritul masinii trece liber pe toata linia soselei")
		return
	_fail = true
	print("ATINGE MASINA (%d):" % real.size())
	for name: String in real:
		var e: Array = hits[name]
		print("  %-38s frac %.3f  (%s)" % [name, e[0], e[1]])


func _bodies(node: Node, out: Array[StaticBody3D] = []) -> Array[StaticBody3D]:
	for c in node.get_children():
		var body := c as StaticBody3D
		if body != null and String(body.name).ends_with("_col"):
			out.append(body)
		_bodies(c, out)
	return out
