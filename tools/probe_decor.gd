extends SceneTree
## Garda de scena: masoara ce costa fiecare pista si arata DE UNDE vine costul
## (procedural din track.gd, sau dintr-un GLB anume).
##
## Doua metrici, cu roluri diferite:
##
## 1. MATERIALE (testul principal). Un material = (cel putin) un draw call, iar
##    draw call-urile sunt constrangerea reala pentru 60fps pe mid-range. Prinde
##    regresia clasica: cineva pune iar StandardMaterial3D.new() intr-o bucla de
##    decor si fiecare instanta isi capata materialul ei — atunci raportul
##    mesh-uri/material cade spre 1.0 si build-ul pica.
##
## 2. TRIUNGHIURI (instrumentare). Raportate mereu, cu prag larg. Nu erau masurate
##    deloc pana acum, desi CLAUDE.md vorbeste de un buget — vezi
##    MAX_TRIS_PER_TRACK pentru de ce pragul e unde e.
##
## Rulare (toate pistele, cod de iesire 1 daca vreuna pica):
##   godot --headless --path . --script res://tools/probe_decor.gd
## O singura pista, doar pentru raport:
##   godot --headless --path . --script res://tools/probe_decor.gd -- --track=2

## Cate mesh-uri procedurale trebuie sa imparta, in medie, un material.
## Masurat la introducerea garzii: Dunele 2.8 · Track02 7.8 · Track03 7.9.
## Dunele e cazul strans — are multe culori distincte legitime (asfalt, borduri,
## linii, gimmick-uri). Coborarea reala sub pragul asta cere atlasul de paleta,
## vezi docs/blender_export.md.
const MIN_MESHES_PER_MATERIAL: float = 2.5

## Cate mesh-uri procedurale sunt necesare ca raportul sa fie semnificativ.
const MIN_SAMPLE: int = 20

## Plafon de triunghiuri per pista, DERIVAT DIN MASURATOARE.
##
## Istoric, pentru ca cifra sa nu para inventata a doua oara:
##
## CLAUDE.md scria "~50k triunghiuri pe scena", dar cifra aia n-avea nimic in
## spate — fara sursa, fara test pe device, iar garda nici macar nu numara
## triunghiuri. Cand am inceput sa le numaram, pistele erau la 147-163k, din care
## ~110k veniti din primitive Godot lasate la rezolutia implicita (un SphereMesh
## are 64x32 = 4224 de triunghiuri; fiecare tufa de 40cm avea geometria unei
## planete). Dupa reparatie: 24-36k.
##
## Pragul a stat apoi la 100k, larg intentionat, cat timp se construia canionul —
## ca sa prinda exploziile accidentale fara sa blocheze munca pe o presupunere.
## A prins una reala: prima versiune a decorului pe benzi a sarit la 117k.
##
## Acum, cu canionul complet, Dunele (cea mai incarcata pista) e la ~65k. Pragul
## e masuratoarea aia plus ~20% marja. Peste pista mai intra ~4k de masini si
## particulele, deci 80k lasa loc si pentru ele.
##
## Ramane un prag de ALARMA, nu un buget de arta: constrangerea reala pe mobil e
## draw calls / overdraw / fill rate, de asta testul principal al garzii ramane
## numaratoarea de MATERIALE. Validarea finala e primul test pe device.
const MAX_TRIS_PER_TRACK: int = 80000

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _rows: Array[Dictionary] = []


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 10):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_decor: nu am gasit nicio pista")
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		if _index >= _paths.size():
			return _report()
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false

	_frames += 1
	if _frames < 3:
		return false # lasam rebuild() sa termine

	_rows.append(_measure(_paths[_index], _track))
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


func _measure(path: String, track: Node) -> Dictionary:
	var world_mat := Palette.world_material()
	# Falezele oglindite folosesc geamanul cu CULL_FRONT. Fara linia asta,
	# jumatate din ele n-ar mai fi numarate ca fiind pe atlas.
	var world_mat_mirror := Palette.world_material_mirrored()
	var by_source := {}
	var all_mats := {}
	var unique_meshes := {}
	var mesh_count := 0
	var on_atlas := 0
	var tris := 0
	# Triunghiurile unei resurse Mesh se numara O SINGURA DATA si se refolosesc:
	# 60 de cactusi care partajeaza acelasi mesh nu justifica 60 de get_faces(),
	# fiecare din ele o copie a intregii geometrii.
	var tris_cache := {}

	for node in _walk(track):
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		mesh_count += 1
		var mat: Material = mi.material_override
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat == world_mat or mat == world_mat_mirror:
			on_atlas += 1
		var key := mat.get_instance_id() if mat != null else 0
		all_mats[key] = true
		if mi.mesh != null:
			var mesh_key := mi.mesh.get_instance_id()
			unique_meshes[mesh_key] = true
			if not tris_cache.has(mesh_key):
				tris_cache[mesh_key] = _tris_of(mi.mesh)
			tris += tris_cache[mesh_key]
		var src := _source_of(mi, track)
		if not by_source.has(src):
			by_source[src] = {"mats": {}, "meshes": 0, "tris": 0}
		by_source[src].mats[key] = true
		by_source[src].meshes += 1
		if mi.mesh != null:
			by_source[src].tris += tris_cache[mi.mesh.get_instance_id()]

	var proc: Dictionary = by_source.get("procedural (track.gd)",
		{"mats": {}, "meshes": 0, "tris": 0})
	var proc_meshes: int = proc.meshes
	var proc_mats: int = proc.mats.size()
	var ratio := float(proc_meshes) / float(maxi(proc_mats, 1))
	var ratio_ok := proc_meshes < MIN_SAMPLE or ratio >= MIN_MESHES_PER_MATERIAL
	return {
		"path": path.get_file().get_basename(),
		"meshes": mesh_count,
		"materials": all_mats.size(),
		"on_atlas": on_atlas,
		"proc_meshes": proc_meshes,
		"proc_materials": proc_mats,
		"ratio": ratio,
		"tris": tris,
		"unique_meshes": unique_meshes.size(),
		"ratio_ok": ratio_ok,
		"tris_ok": tris <= MAX_TRIS_PER_TRACK,
		"ok": ratio_ok and tris <= MAX_TRIS_PER_TRACK,
		"sources": by_source,
	}


## Triunghiurile unui mesh. ArrayMesh-urile generate cu SurfaceTool nu sunt
## indexate, deci get_faces() e sursa corecta indiferent de tip.
func _tris_of(mesh: Mesh) -> int:
	var faces := mesh.get_faces()
	return faces.size() / 3


func _report() -> bool:
	var failed := false
	print("=== GARDA DE SCENA (materiale: prag %.1f mesh-uri proc./material · triunghiuri: alarma la %s) ==="
		% [MIN_MESHES_PER_MATERIAL, _thousands(MAX_TRIS_PER_TRACK)])
	print("%-10s %7s %6s %6s %11s %7s %9s %7s %7s"
		% ["pista", "mesh-uri", "mat.", "atlas", "procedural", "raport",
			"triunghi", "unice", "stare"])
	print("-".repeat(82))
	for row in _rows:
		if not row.ok:
			failed = true
		var state := "OK"
		if not row.ratio_ok and not row.tris_ok:
			state = "PICA×2"
		elif not row.ratio_ok:
			state = "MAT"
		elif not row.tris_ok:
			state = "TRIS"
		print("%-10s %7d %6d %6d %5d/%-5d %7.2f %9s %7d %7s" % [
			row.path, row.meshes, row.materials, row.on_atlas,
			row.proc_meshes, row.proc_materials, row.ratio,
			_thousands(row.tris), row.unique_meshes, state])

	for row in _rows:
		print("\n%s — pe surse:" % row.path)
		var keys: Array = row.sources.keys()
		keys.sort_custom(func(a, b): return row.sources[a].tris > row.sources[b].tris)
		for src in keys:
			print("  %-26s %4d mesh-uri  %3d materiale  %8s tris"
				% [src, row.sources[src].meshes, row.sources[src].mats.size(),
					_thousands(row.sources[src].tris)])

	print("\nVERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	quit(1 if failed else 0)
	return true


## 47200 -> "47 200". Cifrele de triunghiuri se compara intre rulari, iar la 5-6
## cifre lipite ochiul rateaza un ordin de marime.
func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = " " + out
	return out


## De unde vine mesh-ul: dintr-un GLB importat (are ca stramos un nod numit dupa
## fisier) sau construit procedural in track.gd.
##
## ATENTIE cand adaugi un GLB nou in lume: daca numele lui NU e in lista de mai
## jos, mesh-urile lui sunt puse la socoteala drept "procedurale". Cu cateva zeci
## de faleze si cateva sute de prop-uri clasificate gresit, raportul
## mesh-uri/material sare la valori absurde si garda **trece orice** — devine
## decorativa exact cand ai cea mai mare nevoie de ea.
func _source_of(mi: MeshInstance3D, track: Node) -> String:
	const KNOWN := ["cactus", "rocks", "bucket", "sandcastle", "start_arch", "beach_ball",
		"toy_excavator", "toy_dino", "garden_hose", "bowling_pin", "sandbox_border",
		"water_tower", "windmill", "gas_station", "route66",
		# peisajul de canion
		"cliff_wall", "rock_cluster", "desert_scatter", "butte", "wood_fence"]
	var n: Node = mi
	while n != null and n != track:
		var lower := String(n.name).to_lower()
		for k in KNOWN:
			if lower.begins_with(k) or lower.begins_with(k.replace("_", "")):
				return "GLB: " + k
		n = n.get_parent()
	if mi.mesh != null and mi.mesh.get_surface_count() > 0:
		return "procedural (track.gd)"
	return "necunoscut"


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
