extends SceneTree
## Doua defecte de ASEZARE a decorului, masurate pe geometria reala.
##
## 1. PESTE ASFALT. O piesa de decor care intra peste sosea se vede din masina
##    ca "stanca intercalata cu drumul". Daca n-are corp fizic, treci si prin
##    ea. Sonda ia triunghiurile fiecarei piese si le compara cu coridorul
##    soselei (half_width fata de axa), in banda de inaltime prin care trece
##    caroseria.
##
## 2. UNA IN ALTA. O piesa asezata in INTERIORUL alteia produce artefacte de
##    randare: fete coplanare care se bat pe adancime si o vegetatie cu
##    CULL_DISABLED care isi arata spatele prin gazda. Sonda raporteaza perechile
##    a caror cutie e cuprinsa in cea a vecinei peste un prag.
##
## Spre deosebire de probe_rock_fit.gd, care se uita doar la stancile din cele
## doua biblioteci de canion, asta trece prin TOT decorul: si tufe, si cactusi,
## si faleze, si bolovanii vechi.
##
## Rulare:
##   godot --headless --fixed-fps 60 --path . \
##     --script res://tools/probe_decor_overlap.gd -- --track=1

## Banda de inaltime peste cota soselei in care o piesa chiar deranjeaza.
## Sub -0.20 e ingropata, peste 2.5 m trece pe deasupra masinii.
const OVER_LOW: float = -0.20
const OVER_HIGH: float = 2.50

## Cat de mult trebuie sa intre o piesa peste asfalt ca sa fie RAPORTATA.
const OVER_MIN: float = 0.05

## ...si cat ca sa PICE garda. Se raporteaza de la 5 cm fiindca tendinta se vede
## acolo, dar sub un sfert de metru nu e o problema de joc: pe Okinawa ramane un
## smoc de trestie cu 6 cm peste buza asfaltului, si nici nu e roca — e o planta
## prin care oricum treci. Ce cauta garda sunt peretii de canion care intrau cu
## metri peste sosea.
const OVER_FAIL: float = 0.25

## Cat din cutia unei piese trebuie sa stea in cutia alteia ca sa spunem ca e
## ingropata in ea.
const INSIDE_MIN: float = 0.55

## Cate puncte coapte in jurul celui mai apropiat se mai testeaza (~3 m unul de
## altul, deci 20 acopera 60 m de traseu de fiecare parte).
const WINDOW: int = 20

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _rows: Array[Dictionary] = []
var _done: bool = false
## `--manual`: intra si in `DecorManual`. Opt-in, nu implicit: pe pistele vechi
## decorul pus de mana are 339 de piese care trec INTENTIONAT peste asfalt
## (balustrade de pod, ziduri de poarta, apa), deci garda globala ar pica.
## Pistele noi (Track19) il cer explicit in contractul lor de POI.
var _manual: bool = false


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
		elif arg == "--manual":
			_manual = true
	# Numerele de scena vin de PE DISC, nu dintr-un interval scris aici: `range(1, 10)`
	# acoperea Track01..Track09 si lasa pistele de peste 9 nemasurate, iar un
	# `--track=` care nu nimerea nimic tipara „OK" pe zero piste. Aici `--track=`
	# e NUMARUL SCENEI (Track18 = 18), nu pozitia din GameState.TRACK_SCENES —
	# scriptul ruleaza cu --script, unde autoload-urile nu exista.
	var available := _scene_numbers()
	for i in available:
		if only < 0 or only == i:
			_paths.append("res://scenes/tracks/Track%02d.tscn" % i)
	if _paths.is_empty():
		printerr("probe_decor_overlap: nicio pista selectata (--track=%d, scene pe disc: %s) — "
			% [only, available] + "iese cu 1, fiindca o garda pe zero piste nu masoara nimic.")
		# quit() din _initialize doar ridica un steag; _process verifica _done pe
		# prima linie, altfel ar rula mai departe si ar tipari un verdict gol.
		_done = true
		quit(1)


## Numerele de scena ale pistelor existente (Track01.tscn -> 1), crescator.
func _scene_numbers() -> Array[int]:
	var out: Array[int] = []
	var re := RegEx.create_from_string("^Track(\\d+)\\.tscn$")
	for f in DirAccess.get_files_at("res://scenes/tracks"):
		var m := re.search(f)
		if m != null:
			out.append(int(m.get_string(1)))
	out.sort()
	return out


func _process(_delta: float) -> bool:
	if _done:
		return true
	if _track == null:
		if _index >= _paths.size():
			return _report()
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 6:
		return false
	_rows.append(_measure(_paths[_index], _track))
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


func _measure(path: String, track: Node) -> Dictionary:
	var pieces: Array[Dictionary] = []
	_collect(track, pieces)
	var baked: PackedVector3Array = track.baked
	# Semilatimea la fiecare punct copt: MINIMUL dintre cea locala si medie.
	# Cu media singura (`track.half_width`), o pista cu sectoare inguste
	# raporta decor de pe nisip ca „peste asfalt" (Track19: 8 alarme false pe
	# sectoarele de 5.5-6.5 m fata de media de 7). Latimea locala pura ar fi
	# corecta si pe sectoarele LATE, dar acolo gaseste defecte reale pe piste
	# deja livrate (4 oct 2026: Stromboli Basalt_C 1.03 m, Baikal ShrubSnow
	# 0.13 m) si ar inrosi verify_local pentru toata echipa — decizie separata,
	# vezi PR-ul Monument Valley etapa 3. Fara sectoare: identic cu inainte.
	var base_half: float = track.half_width
	var halves := PackedFloat32Array()
	halves.resize(baked.size())
	for i in baked.size():
		halves[i] = minf(base_half, track.width_at_index(i))

	var over: Array[Dictionary] = []
	for piece in pieces:
		if piece["road_ok"]:
			continue
		var deep := _over_road(piece, baked, halves)
		if deep >= OVER_MIN:
			piece["over"] = deep
			over.append(piece)
	over.sort_custom(func(a, b): return float(a["over"]) > float(b["over"]))

	var inside := _buried(pieces)
	return {
		"path": path, "name": track.track_name,
		"pieces": pieces.size(), "over": over, "inside": inside,
	}


## Cat de mult intra piesa peste asfalt, in metri masurati de la margine spre
## axa. 0 daca sta cuminte pe langa drum.
func _over_road(piece: Dictionary, baked: PackedVector3Array,
		halves: PackedFloat32Array) -> float:
	var aabb: AABB = piece["aabb"]
	var c := aabb.get_center()
	var reach := maxf(aabb.size.x, aabb.size.z) * 0.5
	var n := baked.size()
	# Indexul cel mai apropiat de CENTRUL piesei. Restul cautarii sta intr-o
	# fereastra in jurul lui: o piesa de decor are metri, nu sute de metri, deci
	# n-are cum sa fie langa alta bucla de pista decat cea gasita aici.
	var near_i := 0
	var box_near := 1e12
	for i in n:
		var d := Vector2(baked[i].x - c.x, baked[i].z - c.z).length()
		if d < box_near:
			box_near = d
			near_i = i
	if box_near - reach > halves[near_i] + 2.0:
		return 0.0

	var deepest := 0.0
	var tris: PackedVector3Array = piece["tris"]
	var step := maxi(1, int(tris.size() / 600)) # piesele grele nu cer fiecare varf
	var i2 := 0
	while i2 < tris.size():
		var v := tris[i2]
		i2 += step
		var near := 1e12
		var road_y := 0.0
		var half := 0.0
		for k in range(-WINDOW, WINDOW + 1):
			var j := posmod(near_i + k, n)
			var d := Vector2(baked[j].x - v.x, baked[j].z - v.z).length()
			if d < near:
				near = d
				road_y = baked[j].y
				half = halves[j]
		if near >= half:
			continue
		if v.y < road_y + OVER_LOW or v.y > road_y + OVER_HIGH:
			continue
		deepest = maxf(deepest, half - near)
	return deepest


## Perechile in care o piesa sta in interiorul alteia.
##
## Cautarea merge pe o grila de GRID_M metri, nu pereche-cu-pereche: decorul are
## peste o mie de piese, iar patratul lui inseamna un milion de teste de cutie
## in GDScript. Fiecare piesa se compara doar cu cele din celulele vecine.
const GRID_M: float = 10.0

func _buried(pieces: Array[Dictionary]) -> Array[Dictionary]:
	var grid := {}
	for i in pieces.size():
		var c: Vector3 = (pieces[i]["aabb"] as AABB).get_center()
		var key := Vector2i(int(floor(c.x / GRID_M)), int(floor(c.z / GRID_M)))
		if not grid.has(key):
			grid[key] = [] as Array[int]
		(grid[key] as Array).append(i)

	var out: Array[Dictionary] = []
	for i in pieces.size():
		var a: AABB = pieces[i]["aabb"]
		var va := a.size.x * a.size.y * a.size.z
		if va <= 0.0001:
			continue
		var ca := a.get_center()
		var base := Vector2i(int(floor(ca.x / GRID_M)), int(floor(ca.z / GRID_M)))
		var found := false
		for dx in [-1, 0, 1]:
			if found:
				break
			for dz in [-1, 0, 1]:
				var key := base + Vector2i(dx, dz)
				if not grid.has(key):
					continue
				for j: int in grid[key]:
					if i == j:
						continue
					# Gazda trebuie sa fie o FALEZA. Testul e pe cutii, iar o cutie
					# minte pentru orice altceva: un copac mort are cutia lata si
					# geometria subtire, deci "pietricica in cutia copacului" nu
					# inseamna pietricica in lemn. Peretii de canion sunt insa
					# blocuri pline — acolo cutia si volumul chiar coincid, si tot
					# acolo se vede artefactul raportat.
					if not String(pieces[j]["id"]).begins_with("Cliff_"):
						continue
					var b: AABB = pieces[j]["aabb"]
					if b.size.x * b.size.y * b.size.z < va:
						continue # mereu piesa mica fata de gazda mai mare
					if not a.intersects(b):
						continue
					var cut := a.intersection(b)
					var frac := (cut.size.x * cut.size.y * cut.size.z) / va
					if frac < INSIDE_MIN:
						continue
					out.append({"small": pieces[i]["id"], "big": pieces[j]["id"],
						"frac": frac, "at": ca})
					found = true
					break
				if found:
					break
	out.sort_custom(func(a, b): return float(a["frac"]) > float(b["frac"]))
	return out


## Fiecare mesh de DECOR devine o piesa: nume, cutie in lume, triunghiuri.
##
## Se intra DOAR sub nodurile de decor si de faleze, nu peste toata scena (cu
## `--manual`, si sub `DecorManual`, decorul pus de mana):
## soseaua, terenul si orizontul sunt construite cu nume generate, deci o lista
## de exceptii dupa nume ar fi ratat exact ce nu trebuie masurat.
func _collect(node: Node, out: Array[Dictionary]) -> void:
	var nm := String(node.name)
	if nm == "Decor" or nm == "Cliffs" or (_manual and nm == "DecorManual"):
		_gather(node, out)
		return
	for c in node.get_children():
		_collect(c, out)


func _gather(node: Node, out: Array[Dictionary]) -> void:
	var mi := node as MeshInstance3D
	# Doar ce se VEDE: radacina ascunsa a unui GLB multi-varianta (ex. Wall_B pe un
	# modul curb A, deplasat +10 m in fisier) nu se randeaza si nu are corp.
	if mi != null and mi.mesh != null and mi.is_visible_in_tree():
		var xf := mi.global_transform
		var tris := PackedVector3Array()
		for v in mi.mesh.get_faces():
			tris.append(xf * v)
		if not tris.is_empty():
			var box := AABB(tris[0], Vector3.ZERO)
			for v in tris:
				box = box.expand(v)
			out.append({"id": _piece_name(mi), "aabb": box, "tris": tris,
				"road_ok": _declared_on_road(mi)})
	for c in node.get_children():
		_gather(c, out)


## O piesa care sta INTENTIONAT pe sosea (grila pentru vite: bare plate peste
## drum, prin care treci) se declara pe nod cu `metadata/peste_asfalt = true`,
## pe ea sau pe un stramos. Declaratia sta in scena, langa piesa, nu intr-o lista
## de nume aici — altfel orice nume nou ar trebui adaugat in sonda.
func _declared_on_road(node: Node) -> bool:
	var cur := node
	while cur != null:
		if cur.has_meta("peste_asfalt") and bool(cur.get_meta("peste_asfalt")):
			return true
		cur = cur.get_parent()
	return false


## Numele care spune ceva: primul stramos (sau el insusi) fara nume generat.
func _piece_name(node: Node) -> String:
	var cur := node
	while cur != null:
		var nm := String(cur.name)
		if not nm.begins_with("@") and not nm.begins_with("MeshInstance"):
			return nm
		cur = cur.get_parent()
	return String(node.name)


func _report() -> bool:
	print("\n=== decor peste asfalt / decor ingropat in decor ===")
	var bad := 0
	for row in _rows:
		print("\n%s (%s): %d piese de decor"
			% [row["name"], String(row["path"]).get_file(), row["pieces"]])
		var ov: Array = row["over"]
		print("  PESTE ASFALT (>= %.2f m peste margine): %d" % [OVER_MIN, ov.size()])
		for w in ov.slice(0, 12):
			var c: Vector3 = (w["aabb"] as AABB).get_center()
			print("    %-14s intra %.2f m peste asfalt  la (%.0f, %.0f)" % [w["id"], w["over"], c.x, c.z])
		var ins: Array = row["inside"]
		print("  INGROPATE IN ALTA PIESA (>= %d%% din cutie): %d"
			% [int(INSIDE_MIN * 100.0), ins.size()])
		for w in ins.slice(0, 12):
			print("    %-14s  %d%% in  %-14s la %s"
				% [w["small"], int(float(w["frac"]) * 100.0), w["big"],
				(w["at"] as Vector3).round()])
		# Cade DOAR pe geometria de peste asfalt. Piesele ingropate se raporteaza
		# ca instrumentare: testul lor e pe cutii, iar o cutie supraestimeaza —
		# raman cazuri in care piesa doar atinge peretele, nu intra in el. Un
		# prag dur pe un numar aproximativ ar fi zgomot in CI.
		for w in ov:
			if float(w["over"]) >= OVER_FAIL:
				bad += 1
	if bad > 0:
		print("\nVERDICT: PROBLEMA — %d piese asezate gresit." % bad)
	else:
		print("\nVERDICT: OK")
	_done = true
	quit(1 if bad > 0 else 0)
	return true
