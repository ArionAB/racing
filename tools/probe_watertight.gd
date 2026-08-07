extends SceneTree
## Cate mesh-uri din biblioteca de modele sunt SPARTE: au muchii de contur —
## muchii folosite de o singura fata, adica gauri in suprafata.
##
##   godot --headless --path . --script res://tools/probe_watertight.gd
##   ... -- --all      listeaza si mesh-urile sanatoase
##
## DE CE CONTEAZA. Godot deseneaza doar fetele intoarse spre camera. Pe un
## solid inchis asta e exact ce vrei — fetele din spate n-au ce cauta pe ecran.
## Pe un mesh cu gauri, prin gaura vezi spatele peretelui opus, care e cules:
## rezultatul citeste ca „stanca e goala pe dinauntru". De aici a plecat sonda.
##
## SE MASOARA PE POZITIE, NU PE INDICI, si asta e toata smecheria. glTF nu
## stocheaza vertecsi, stocheaza varfuri de FATA: un mesh cu fatete plate isi
## despica fiecare vertex pe cate normale au fetele din jur. Numarate pe indici,
## TOATE modelele apar sparte (Rock_Medium_1 din kit: 316 muchii de contur din
## 671, desi obiectul e etans). Cu vertecsii sudati pe pozitie, cifra spune ce
## trebuie: cat din suprafata chiar lipseste.
##
## CE SE EXCLUDE, si de ce nu e o scutire. Vegetatia din Stylized Nature
## MegaKit e construita din FOI deschise, prin constructie — de aceea are
## material propriu fara backface culling (`Palette.foliage_material`), deci
## gaurile ei nu se vad niciodata. Ce ramane in raport sunt mesh-urile pe care
## le desenam ca solide.
##
## Cod de iesire 1 daca vreun solid are peste PRAG_PROCENT din muchii deschise.

## Sub atat e o gaura izolata (un triunghi lipsa intr-o pietricica), peste
## inseamna suprafata rupta. Cazul care a cerut sonda avea 17-62%.
const FAIL_PCT: float = 3.0
## Vertecsii mai apropiati de atat (in metri) sunt acelasi vertex.
const WELD: float = 0.001
## Fisierele in care geometria deschisa e intentionata — se randeaza cu
## material fara culling, deci n-au cum sa arate un interior.
const FOLIAGE := ["megakit_plants.glb", "hibiscus_bush.glb", "pandanus.glb",
	"coconut_palm.glb", "beach_palm_bent.glb", "banyan.glb",
	"sugar_cane_clump.glb", "cactus.glb"]

## DATORIA CUNOSCUTA, masurata in august 2026 cand a fost scrisa sonda. Sunt
## prop-uri mici, construite inainte sa existe masuratoarea; gaurile lor se vad
## doar din unghiuri anume si niciunul nu e o suprafata care sa umple cadrul,
## cum erau stancile de la care a plecat totul.
##
## Lista NU e o scutire, e o inventariere: orice mesh care nu e aici si trece de
## prag pica garda, si la fel oricare de aici care se INRAUTATESTE. Cine repara
## un asset de pe lista sterge randul lui, si de atunci inainte e aparat.
const KNOWN := {
	"sand_shovel.glb:sand_shovel": 12.5,
	"pipe_leak.glb:Pipe_Elbow": 11.9,
	"chevron_sign.glb:Chevron_A": 8.3,
	"beach_ball.glb:beach_ball": 7.1,
	"sandcastle.glb:sandcastle": 6.8,
	"chevron_sign.glb:Chevron_B": 5.7,
	"chevron_sign.glb:Chevron_C": 5.7,
	"tetrapod.glb:Tetrapod_01": 5.3,
	"tetrapod.glb:Tetrapod_04": 5.3,
	"tetrapod.glb:Tetrapod_Stack_01": 5.3,
}
## Cat poate creste o cifra din lista inainte sa fie considerata regresie.
const KNOWN_SLACK: float = 0.3

var _rows: Array[Dictionary] = []


func _initialize() -> void:
	var show_all := "--all" in OS.get_cmdline_user_args()
	var dir := DirAccess.open("res://assets/models")
	if dir == null:
		print("nu gasesc res://assets/models")
		quit(1)
		return
	# modelele stau in foldere de categorie (rocks/, trees/, ...); cheile din
	# FOLIAGE si KNOWN raman nume scurte, deci raportul pastreaza doar fisierul
	var files: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".glb"):
			files.append(f)
	for sub in dir.get_directories():
		var sub_dir := DirAccess.open("res://assets/models/" + sub)
		if sub_dir == null:
			continue
		for f in sub_dir.get_files():
			if f.ends_with(".glb"):
				files.append(sub + "/" + f)
	files.sort()

	for path in files:
		var f := path.get_file()
		if f in FOLIAGE:
			continue
		var scene := (load("res://assets/models/" + path) as PackedScene) \
			.instantiate()
		_walk(f, scene)
		scene.free()

	_rows.sort_custom(func(a, b): return float(a["pct"]) > float(b["pct"]))
	print("\n=== SUPRAFETE SPARTE (muchii de contur, vertecsi sudati) ===")
	var bad := 0
	var debt := 0
	for r in _rows:
		var pct := float(r["pct"])
		var key := "%s:%s" % [r["file"], r["name"]]
		var state := ""
		if pct >= FAIL_PCT:
			if KNOWN.has(key) and pct <= float(KNOWN[key]) + KNOWN_SLACK:
				state = "  (datorie cunoscuta)"
				debt += 1
			else:
				state = "  <-- REGRESIE"
				bad += 1
		if show_all or pct > 0.0:
			print("  %-22s %-16s tri=%5d  contur=%4d (%4.1f%%)%s"
				% [r["file"], r["name"], r["tri"], r["border"], pct, state])
	print("  %d mesh-uri masurate, %d datorii cunoscute, %d peste prag (%.1f%%)"
		% [_rows.size(), debt, bad, FAIL_PCT])
	if bad > 0:
		print("VERDICT: PROBLEMA — se vede in interiorul lor.")
		quit(1)
		return
	print("VERDICT: OK")
	quit()


func _walk(file: String, node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		_measure(file, _owner_name(mi), mi.mesh)
	for c in node.get_children():
		_walk(file, c)


## Numele care spune ceva: primul stramos (sau el insusi) fara nume generat.
func _owner_name(node: Node) -> String:
	var cur := node
	while cur != null:
		var nm := String(cur.name)
		if not nm.begins_with("@") and not nm.begins_with("MeshInstance"):
			return nm
		cur = cur.get_parent()
	return String(node.name)


func _measure(file: String, name: String, mesh: Mesh) -> void:
	var faces := mesh.get_faces()
	if faces.is_empty():
		return
	var edges := {}
	var tri := faces.size() / 3
	for t in tri:
		var v := [faces[t * 3], faces[t * 3 + 1], faces[t * 3 + 2]]
		for i in 3:
			var ka := _key(v[i])
			var kb := _key(v[(i + 1) % 3])
			var k := ka + "|" + kb if ka < kb else kb + "|" + ka
			edges[k] = int(edges.get(k, 0)) + 1
	var border := 0
	for k in edges:
		if int(edges[k]) == 1:
			border += 1
	_rows.append({
		"file": file, "name": name, "tri": tri, "border": border,
		"pct": 100.0 * float(border) / maxf(1.0, float(edges.size())),
	})


func _key(v: Vector3) -> String:
	return "%d,%d,%d" % [roundi(v.x / WELD), roundi(v.y / WELD), roundi(v.z / WELD)]
