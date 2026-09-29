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
##   ... -- --track=1

## Peste atat deasupra terenului, obiectul pluteste vizibil.
const FLOAT_MAX: float = 3.0
## Sub atat fata de teren, s-a ingropat.
const SINK_MAX: float = 2.0
## Metadata pentru piesele scufundate PRIN PROIECT si cat trebuie sa iasa
## varful lor din teren ca sa nu fie totusi ingropate (vezi `_report`).
const SUNK_META := "scufundat"
const SUNK_MIN_VISIBLE: float = 0.8
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
		# Ancora de sol OPT-IN (metadata `ancora_sol`, punct LOCAL): piesele
		# care sunt FATADE lipite de un perete de teren (modulele de trepte ale
		# fantanii Jodhpur, POI C) au originea la mijlocul bazei, deci 1,5 m
		# INAUNTRUL peretelui, unde terenul e prin proiect cu 2-4 m peste baza.
		# Pentru ele baza vizibila e muchia de jos a FETEI; acolo se judeca
		# plutit/ingropat. Fara metadata, comportamentul e cel de dinainte.
		if n3.has_meta("ancora_sol"):
			p = n3.global_transform * (n3.get_meta("ancora_sol") as Vector3)
		var ground: float = t._sampler.ground_y(p.x, p.z)
		var near := 1e9
		var near_i := 0
		for i in baked.size():
			var d := Vector2(p.x - baked[i].x, p.z - baked[i].z).length()
			if d < near:
				near = d
				near_i = i
		var verdict := "ok"
		if ground < sea_y and absf(p.y - sea_y) <= 1.0:
			verdict = "ok (pe apa)"
		elif p.y - ground > FLOAT_MAX and _on_static_face(n3):
			verdict = "ok (pe stanca)"
		elif p.y - ground > FLOAT_MAX and _under_airborne_mover(n3):
			verdict = "ok (in zbor)"
		elif p.y - ground > FLOAT_MAX:
			verdict = "PLUTESTE"
		elif ground - p.y > SINK_MAX and n3.has_meta(SUNK_META):
			# Scufundat PRIN PROIECT (zidurile-parapet ale portilor Jodhpur: un
			# zid de 14 m ingropat pana ii raman crenelurile peste drum). Nu se
			# iarta pe declaratie: se masoara VARFUL real al mesh-ului, care
			# trebuie sa iasa din teren cu cel putin SUNK_MIN_VISIBLE — altfel
			# terenul l-a inghitit si e tot INGROPAT.
			var top := _top_y(n3)
			if top - ground >= SUNK_MIN_VISIBLE:
				verdict = "ok (scufundat, varf %+.1f m)" % (top - ground)
			else:
				verdict = "INGROPAT (varf %+.1f m)" % (top - ground)
		elif ground - p.y > SINK_MAX:
			verdict = "INGROPAT"
		# Latimea LOCALA, nu `half_width`. Pe o pista cu profil de latime
		# (Baikal: 6 m in grota, 11 m pe gheata) marginea masurata fata de
		# latimea implicita raporteaza "IN DRUM" obiecte asezate cuminte langa
		# asfaltul lat, si trece cu vederea unele chiar pe asfaltul ingust.
		var hw_here: float = t.width_at(t.frac_at(near_i))
		# O piesa cu coliziune "none" (fantoma, world_prop.gd) nu poate opri
		# masina, deci "IN DRUM" e fara sens pentru ea — la fel de fals ca
		# la Fiordland POI C: muschiul de pe TAVANUL buzei surplombului e la
		# 20+ m peste asfalt, lateral aproape de ax fiindca buza chiar iese
		# peste drum (asa cere brief-ul), dar n-are corp fizic care sa loveasca
		# masina. Verificarea e pe MODUL REZOLVAT (metadata proprie, apoi
		# `PROP_COLLISION` dupa numele fisierului), nu pe nume de prefix.
		if (near < hw_here + ROAD_MARGIN and not _spans_road(entry["path"])
				and _effective_collision_mode(n3) != "none"):
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


## Piesele care TREC peste sosea, prin proiect: portalul de tunel si arcada de
## viaduct au drumul pe sub ele, poarta de start si arcul grotei il incaleca.
## Pentru astea "aproape de ax" e specificatia, nu defectul — asa cum pentru o
## barca "sub nivelul terenului" e specificatia, iar sonda are deja exceptia aia
## de la inceput.
##
## Recunoasterea se face dupa NUME fiindca sonda citeste scena coapta, unde
## intentia autorului nu mai exista ca date — generatorul o marcheaza cu
## `spans_road`, dar `.tscn` pastreaza doar nodul. Numele sunt cele emise de
## tools/gen_decor_baikal.gd.
const SPANS_ROAD_PREFIXES: Array[String] = [
	"PoartaStart", "Grota", "Arcada", "Pila", "CapatViaduct", "PortalTunel",
	"chasmBridgeRail",
	# Jodhpur POI E: portile fortului (coliziune `mesh`, drumul trece prin gol).
	"PoartaFort",
]

## Modul de coliziune REZOLVAT pentru un prop asezat de mana: metadata proprie
## `coliziune` daca exista, altfel implicitul din `WorldProp.PROP_COLLISION`
## dupa numele fisierului .glb — aceeasi regula pe care o aplica
## `world_prop.gd` cand construieste corpurile la rulare (`_collision_mode`).
## Recalculata aici (nu apelata direct pe instanta WorldProp, care nu exista
## la acest nivel) ca sa citim intentia FARA sa depindem de un nume de prefix.
static func _effective_collision_mode(n3: Node3D) -> String:
	if n3.has_meta(WorldProp.COLLISION_META):
		var m := String(n3.get_meta(WorldProp.COLLISION_META))
		if WorldProp.COLLISION_MODES.has(m):
			return m
	var stem := n3.scene_file_path.get_file().get_basename()
	return String(WorldProp.PROP_COLLISION.get(stem, "hull"))


## Cota cea mai inalta a mesh-urilor vizibile ale unei instante (lume).
static func _top_y(n3: Node3D) -> float:
	var top := -INF
	for mi in n3.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf := m.global_transform
		var bb := m.mesh.get_aabb()
		for k in 8:
			top = maxf(top, (xf * bb.get_endpoint(k)).y)
	return top if top > -INF else n3.global_position.y


static func _spans_road(path: String) -> bool:
	var leaf := path.get_file() if path.contains("/") else path
	for prefix in SPANS_ROAD_PREFIXES:
		if leaf.begins_with(prefix):
			return true
	return false


## Piesele agatate pe FATA unei stanci mari, nu pe teren — ca la Fiordland
## POI C (Cascada Stirling): `stirling_ledge` e un surplomb la +14..+21 m
## peste axa drumului, iar muschiul de pe buza lui e ancorat prin raycast pe
## coliziunea REALA a stancii (`tools/gen_decor_fiord_c.gd`), nu pe teren.
## `ground` (terenul de dedesubt) e la ~15-23 m mai jos prin CONSTRUCTIE —
## la fel cum o barca sta sub `ground` langa chei, moara asta sta deasupra
## lui langa perete.
##
## FOST: exceptie pe NUME (prefix `muschiBuza`) — trecea orice piesa cu numele
## asta chiar daca chiar PLUTEA (nimic nu verifica fizic ca piesa atinge ceva).
## ACUM: test FIZIC. O raza in jos din piesa trebuie sa loveasca un corp STATIC
## care NU e `TerrainBody` si NU e propriul colizor al piesei (numit `<nume>_col`
## de `world_prop.gd`), la o distanta <= FLOAT_MAX de piesa — adica piesa chiar
## sta lipita de o stanca/structura reala (stirling_ledge, chasm_rock etc.), nu
## doar poarta un nume care suna a asta. Toleranta mica negativa (SINK_MAX)
## pentru piese usor ingropate in hull-ul stancii (ancorate cu -0.05 in
## `gen_decor_fiord_c.gd`, ca sa nu pluteasca vizibil).
##
## Sabotaj verificat manual (raport): ridicarea temporara a `muschiBuza0` cu
## 3 m a facut raza sa NU mai loveasca nimic in FLOAT_MAX (cade liber spre
## TerrainBody, la 15+ m) — garda o prinde ca PLUTESTE. Revenit imediat dupa.
##
## O SINGURA raza in jos rateaza piesele agatate pe o fata VERTICALA a stancii
## (muschiul de pe flancul lateral al `stirlingLedge`, nu pe tavanul
## orizontal): dedesubtul lor e aer liber, nu stanca. De aceea se incearca
## 5 directii — jos si cele 4 orizontale — si e suficient ca UNA sa loveasca
## structura reala la distanta mica: o piesa lipita de perete o atinge
## indiferent pe ce fata (podea, tavan sau flanc).
const _PROBE_DIRS: Array[Vector3] = [
	Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(-1, 0, 0),
	Vector3(0, 0, 1), Vector3(0, 0, -1),
]

## Piesa e carata de un PathMover cu `stick_to_ground = false` (avionul de pe
## Fiordland POI H, `bush_plane` pe traiectorie in aer, `--allow-car-slots`
## nu se aplica) — inaltimea peste teren e INTENTIA, nu un accident de
## generator. Acelasi tipar ca exceptia de apa/stanca de mai sus: se verifica
## un fapt STRUCTURAL (un stramos concret cu flagul pus), nu un nume de
## prefix, ca sa nu treaca in tacere un obiect plutitor pus GRESIT langa un
## PathMover care intamplator se numeste la fel.
static func _under_airborne_mover(n3: Node3D) -> bool:
	var cur: Node = n3
	while cur != null:
		var mover := cur as PathMover
		if mover != null:
			return not mover.stick_to_ground
		cur = cur.get_parent()
	return false


static func _on_static_face(n3: Node3D) -> bool:
	var world := n3.get_world_3d()
	if world == null:
		return false
	var space_state := world.direct_space_state
	var p := n3.global_position
	var self_col_name := "%s_col" % n3.name
	var range_m := FLOAT_MAX + 0.5
	for dir: Vector3 in _PROBE_DIRS:
		var from := p - dir * 0.5
		var to := p + dir * range_m
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_bodies = true
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider0: Object = hit.get("collider")
			if collider0 is Node and str((collider0 as Node).name) == self_col_name:
				query.exclude = [(collider0 as CollisionObject3D).get_rid()]
				hit = space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var collider: Object = hit.get("collider")
		if collider == null:
			continue
		var body := collider as Node
		if body != null and (str(body.name) == "TerrainBody" or str(body.name) == self_col_name):
			continue
		var hit_pos: Vector3 = hit["position"]
		var dist: float = (hit_pos - p).length()
		if dist <= FLOAT_MAX:
			return true
	return false
