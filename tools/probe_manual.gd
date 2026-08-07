extends SceneTree
## Sonda pentru DECORUL ASEZAT DE MANA: ce pluteste, ce e ingropat, ce a ajuns
## in drum.
##
## Exista fiindca `docs/decor_manual.md` avertizeaza de doua lucruri care nu se
## vad din editor: (1) terenul se recalculeaza cand tragi de curba, deci
## obiectele raman suspendate sau ingropate, si (2) generatorul procedural nu
## stie de obiectele tale. Pana acum singurul mod de a le prinde era sa te uiti.
##
## Prima rulare pe Dunele (#151) a gasit, din noua obiecte: unul la 128 m in
## aer, patru care pluteau intre 2.7 si 23 m, si patru asezate PE CAROSABIL —
## o arcada la 2.2 m de axul soselei si un cactus la 3.2 m. Nimic din toate
## astea nu se vedea in joc, fiindca nodul era pe `visible = false`.
##
##   godot --headless --path . --script res://tools/probe_manual.gd
##   ... -- --track=5

## Peste atat deasupra terenului, obiectul pluteste vizibil.
const FLOAT_MAX: float = 3.0
## Sub atat fata de teren, s-a ingropat.
const SINK_MAX: float = 2.0
## Marja peste jumatatea de sosea sub care obiectul e practic pe carosabil.
const ROAD_MARGIN: float = 2.0

var _frames := 0
var _track: Node = null


func _process(_delta: float) -> bool:
	if _track == null:
		var idx := 1
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				idx = int(a.trim_prefix("--track="))
		var path := "res://scenes/tracks/Track%02d.tscn" % idx
		if not ResourceLoader.exists(path):
			push_error("probe_manual: nu exista %s" % path)
			quit(1)
			return true
		print("=== %s ===" % path)
		_track = (load(path) as PackedScene).instantiate()
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	quit(0 if _report() else 1)
	return true


func _report() -> bool:
	var t: Node3D = _track
	var manual: Node3D = t.get_node_or_null("DecorManual")
	if manual == null:
		print("nicio pista nu are DecorManual — nimic de verificat")
		return true
	var props := _props(manual, "")
	print("DecorManual.visible = %s, %d obiecte" % [manual.visible, props.size()])
	var baked: PackedVector3Array = t.baked
	# Prop-urile DE APA (ponton, barca, stanci in valuri) se judeca fata de
	# nivelul marii, nu fata de teren: o barca pe apa "pluteste" la 4 m peste
	# fundul lagunei si o stanca in valuri e "ingropata" fata de mal — ambele
	# corecte. Regula: daca terenul de sub prop e sub nivelul marii, ancora e
	# marea. Pe pistele fara mare, sea_y iese la -1e9 si regula nu se atinge.
	var sea_y := -1e9
	if "sea_level_offset" in t and t._sampler != null:
		sea_y = t._sampler.mean_road_y() + t.sea_level_offset
	var bad := 0
	print("%-40s %9s %9s %8s   %11s   %s" % ["obiect", "y_obiect", "y_teren",
		"delta", "dist. la ax", "verdict"])
	for entry in props:
		var n3: Node3D = entry["node"]
		var p := n3.global_position
		var ground: float = t._sampler.ground_y(p.x, p.z)
		var near := 1e9
		for i in baked.size():
			near = minf(near, Vector2(p.x - baked[i].x, p.z - baked[i].z).length())
		var verdict := "ok"
		if ground < sea_y and absf(p.y - sea_y) <= 1.0:
			verdict = "ok (pe apa)"
		elif p.y - ground > FLOAT_MAX:
			verdict = "PLUTESTE"
		elif ground - p.y > SINK_MAX:
			verdict = "INGROPAT"
		if near < t.half_width + ROAD_MARGIN:
			verdict += " / IN DRUM"
		if not verdict.begins_with("ok") or verdict.contains("IN DRUM"):
			bad += 1
		print("%-40s %9.2f %9.2f %8.2f   %9.1f m   %s" % [entry["path"], p.y,
			ground, p.y - ground, near, verdict])
	if bad > 0:
		print("VERDICT: %d obiecte de reparat (Snap Object to Floor sau mutare)"
			% bad)
		return false
	print("VERDICT: OK")
	return true


## Prop-urile din subarborele lui DecorManual, cu calea relativa pentru raport.
##
## Recursiv, si NU din exces de zel: decorul e grupat pe zone (`Zone02_Harbour`
## etc.), deci o bucla peste copiii directi ar masura containerele — care stau la
## originea scenei, adica departe de pista, deci ar raporta „PLUTESTE" pentru
## niste noduri goale si zero pentru prop-urile reale. Varianta pe un nivel rata
## si prop-urile agatate de alt prop: pe Track08 erau 30 nevazute.
##
## Un prop = un nod cu `scene_file_path` (radacina unei instante de GLB). Nodurile
## de grupare adaugate in editor n-au, iar mesh-urile din interiorul unui GLB
## apar ca parte a instantei, nu ca instante separate — deci exact granularitatea
## la care ai tras obiectul in scena.
func _props(node: Node, prefix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in node.get_children():
		var n3 := c as Node3D
		if n3 == null:
			continue
		var path := prefix + String(c.name)
		if not n3.scene_file_path.is_empty():
			out.append({"node": n3, "path": path})
		out.append_array(_props(n3, path + "/"))
	return out
